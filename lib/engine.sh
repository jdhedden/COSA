#!/usr/bin/bash

ce_params () {
    # USAGE: de_params
    local ep_prm=(Depth Lines Threads Hash Contempt)

    cat <<__PARAMS__

Engine parameters:
  Depth: ${ENG[depth]}
  Lines: ${ENG[/MultiPV]}
  Threads: ${ENG[/Threads]}
  Hash: ${ENG[/Hash]}
  Contempt: ${ENG[/Contempt]}

__PARAMS__

    PS3='
Which paramater? '
    local ep_opt
    select ep_opt in "${ep_prm[@]}"; do
        if [[ -n $ep_opt ]]; then
            read -p "Value for $ep_opt parameter? "
            if [[ -n $REPLY ]]; then
                case $ep_opt in
                    Depth)    ENG[depth]=$REPLY ;;
                    Lines)    ENG[/Hash]=$REPLY ;;
                    Threads)  ENG[/Threads]=$REPLY ;;
                    Hash)     ENG[/Hash]=$REPLY ;;
                    Contempt) ENG[/Contempt]=$REPLY ;;
                esac
            fi
        fi
    done
}


ce_run () {
    # USAGE: ce_run "$fen" results

    # Returns:
    #   results[time]
    #   results[#]
    #   results[err]

    #local rn_fen=$1
    local -n rn_res=$2

    local ii

    if [[ -z ${ENG[ENG]} ]]; then
        rn_res[err]='Engine not available on this platform'
        return 1
    fi

    # Check for engine binary
    if [[ ! -f ${ENG[ENG]} ]]; then
        rn_res[err]="Engine not found: ${ENG[ENG]}"
        return 1
    fi

    # Set up FIFOs
    rm -f ${ENG[TO]} ${ENG[FM]}
    mkfifo ${ENG[TO]}
    mkfifo ${ENG[FM]}

    # Launch the engine
    echo "FEN: $1" >${ENG[LOG]}
    tee -a ${ENG[LOG]} <<__PARAMS__

Engine parameters:
  Depth: ${ENG[depth]}
  Lines: ${ENG[/MultiPV]}
  Threads: ${ENG[/Threads]}
  Hash: ${ENG[/Hash]}
  Contempt: ${ENG[/Contempt]}
  Started: $(date +%H:%M:%S)

__PARAMS__
    SECONDS=0

    ${ENG[ENG]} <${ENG[TO]} >${ENG[FM]} 2>&1 &
    local rn_pid=$!
    disown $rn_pid

    exec 6<>${ENG[TO]}
    exec 7<>${ENG[FM]}

    # Initialize engine
    echo uci >&6
    while kill -0 $rn_pid >/dev/null 2>&1; do
        if read -t 1 -u 7; then
            echo "$REPLY" >>${ENG[LOG]}
            if [[ $REPLY == uciok ]]; then
                break
            elif [[ $REPLY =~ UCI_AnalyseMode ]]; then
                ENG[/UCI_AnalyseMode]=true
            fi
        fi
    done

    # Configure engine options
    if kill -0 $rn_pid >/dev/null 2>&1; then
        for ii in "${!ENG[@]}"; do
            if [[ $ii =~ ^/ ]]; then
                echo "setoption name ${ii:1} value ${ENG[$ii]}" | tee -a ${ENG[LOG]} >&6
            fi
        done

        # Set board
        echo ucinewgame >&6
        echo "position fen $1" | tee -a ${ENG[LOG]} >&6

        echo isready >&6
        while kill -0 $rn_pid >/dev/null 2>&1; do
            if read -t 1 -u 7; then
                echo "$REPLY" >>${ENG[LOG]}
                if [[ $REPLY == readyok ]]; then
                    break
                fi
            fi
        done
    fi

    # Do the analysis
    local rn_min rn_sec rn_depth=1
    if kill -0 $rn_pid >/dev/null 2>&1; then
        echo "go depth ${ENG[depth]}" | tee -a ${ENG[LOG]} >&6
        echo -en "\e[?25l"  # Hide cursor
        while kill -0 $rn_pid >/dev/null 2>&1; do
            if read -t 1 -u 7; then
                if [[ $REPLY =~ currmove ]]; then
                    continue
                fi
                echo "$REPLY" >>${ENG[LOG]}
                if [[ $REPLY =~ \ depth\ ([0-9]+)\ .+\ multipv\ ([0-9]+)\  ]]; then
                    rn_res[${BASH_REMATCH[2]}]=$REPLY
                    if [[ ${BASH_REMATCH[1]} -gt $rn_depth ]]; then
                        rn_depth=${BASH_REMATCH[1]}
                        rn_sec=$SECONDS
                        rn_min=$((rn_sec/60))
                        printf "\015\033[K[%d:%02d] Depth: %d" $rn_min $((rn_sec - 60*rn_min)) $rn_depth
                    fi
                elif [[ $REPLY =~ ^bestmove ]]; then
                    rn_res[time]=$SECONDS
                    break
                fi
            fi
        done
        echo -en "\e[?25h\015\e[K"  # Unhide cursor
    fi

    # Done
    if kill -0 $rn_pid >/dev/null 2>&1; then
        echo quit | tee -a ${ENG[LOG]} >&6
        # Wait for engine to exit
        ii=$(( SECONDS + ENG[KILL_TIME] ))
        while [[ $SECONDS -lt $ii ]]; do
            if ! kill -0 $rn_pid >/dev/null 2>&1; then
                sleep 0.1
            fi
        done
        # Kill if needed
        if kill -9 $rn_pid >/dev/null 2>&1; then
            echo "Killed ${ENG[ENG]} (pid $rn_pid)" >>${ENG[LOG]}
        fi
    else
        rn_res[err]=='Engine terminated prematurely'
        echo "${rn_res[err]}" >>${ENG[LOG]}
    fi

    exec 6>&-
    exec 7>&-
    rm -f ${ENG[TO]} ${ENG[FM]}
}


ce_engine () {
    # USAGE: de_params DB $line $turn $side

    #local en_db=$1
    #local en_l=$2
    #local en_t=$3
    #local en_s=$4

    # Run engine
    local -A en_res
    local en_fen
    if [[ -v "SIMULATED[fen]" ]]; then
        # Simulated engine results
        en_fen=${SIMULATED[fen]}
        en_res[time]=${SIMULATED[time]}
        local en_cnt=1
        while [[ -n ${SIMULATED[$en_cnt]} ]]; do
            en_res[$en_cnt]=${SIMULATED[$en_cnt]}
            (( en_cnt++ ))
        done
    else
        # Run chess engine
        node_get $1 $2.$3.$4.f en_fen
        if ! ce_run "$en_fen" en_res; then
            GBL[ERR]=${en_res[err]}
            return 1
        fi
        GBL[MSG]="Analysis time: ${en_res[time]} secs."
    fi

    # Create new DB
    local -A en_db
    tree_init en_db

    # Get moves for current line (up to current move)
    local -a en_mvs
    cd_gather_moves $1 en_mvs $2 1 w $3 $4

    # Generate line with move
    local en_l
    cd_gen_line en_db en_l "${en_mvs[@]}"

    # Convert engine results create lines
    local en_scr en_scr1 en_tmp en_ll en_tt en_ss
    echo -en "\e[?25l"  # Hide cursor
    local ii=1
    while [[ ${en_res[$ii]} =~ score\ cp\ ([0-9]+)\ .+\ pv\ (([a-h][1-8][a-h][1-8]\ )+) ]]; do
        printf "\015\033[KProcessing result #%d" $ii
        en_scr=${BASH_REMATCH[1]}

        if [[ $ii == 1 ]]; then
            if ! cd_add_moves en_db $en_l en_tt en_ss ${BASH_REMATCH[2]}; then
                echo -e "\e[?25h"  # Unhide cursor
                return 1
            fi
            # Copy comment
            node_get $1 $2.c en_tmp
            node_set en_db $en_l.c "$en_tmp"
            en_scr1=$en_scr
            # Start
            node_set en_db $en_l.s $en_tt.$en_ss
            # Rotation
            if node_get -q $1 $2.r en_tmp; then
                node_set en_db $en_l.r $en_tmp
            fi

        else
            if ! cd_branch_line en_db en_ll $en_l $en_tt $en_ss ${BASH_REMATCH[2]}; then
                echo -e "\e[?25h"  # Unhide cursor
                return 1
            fi
            # Add score to line comment
            node_get en_db $en_l.c en_tmp
            node_set en_db $en_ll.c "$en_tmp (score: $en_scr)"
        fi

        (( ii++ ))
    done
    echo -en "\e[?25h\015\e[K"  # Unhide cursor

    # Add score to main line comment
    node_get en_db $en_l.c en_tmp
    node_set en_db $en_l.c "$en_tmp (score: $en_scr1)"

    # Save to dat/engine
    local en_file
    part -$ . "${GBL[DB_FILE]}" en_file
    part +$ / "$en_file" en_file
    en_file="$COSA/dat/engine/${en_file}_$2-$3-$4.dat"
    cd_save en_db "$en_file"

    # Launch results in new window
    cv_window "$en_file" $en_l.$en_tt.$en_ss
    return 0
}

# EOF
