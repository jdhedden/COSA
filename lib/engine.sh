#!/bin/bash

declare -A ENG=(
    [TO]=$COSA/tmp/stockfish_cmd.fifo
    [FM]=$COSA/tmp/stockfish_out.fifo
    [LOG]=$COSA/log/stockfish.log

    [/Threads]=8
    [/Hash]=8000
    [/MultiPV]=5
    [/Contempt]=100

    [depth]=25

    [KILL_TIME]=3
    [SHOW]=false
)


ce_params() {
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


ce_convert() {
    # USAGE: ce_convert moves "$fen" "${moves[@]}"

    eval "local -n cm_mvs=$1"
    #local cm_fen=$2

    local -A cm_brd
    cm_set_board cm_brd "$2"

    cm_mvs=()
    local cm_m cm_mv
    for cm_m in ${@:3}; do
        if cm_move_eng cm_brd $cm_m cm_mv; then
            cm_mvs+=($cm_mv)
        else
            GBL[ERR]="BUG: Engine move failure\n  Error: '${cm_brd[err]}'\n  Move: $cm_m\n  FEN: '${cm_brd[fen]}'"
            return 1
        fi
    done
    return 0
}


ce_run() {
    # USAGE: ce_run "$fen" results

    # Returns:
    #   results[time]
    #   results[#]
    #   results[err]

    #local rn_fen=$1
    eval "local -n rn_res=$2"

    local ii

    # Platform specific configs
    if [[ $LOC == home ]]; then
        ENG[ENG]=/usr/games/stockfish

    elif [[ $LOC == phone ]]; then
        ENG[ENG]=$HOME/bin/stockfish-10-arm65v8

        ENG[/UCI_AnalyseMode]=true

    else
        rn_res[err]="Engine not available on this platform: LOC='$LOC'"
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
    local rn_min rn_sec
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
                    rn_sec=$SECONDS
                    rn_min=$((rn_sec/60))
                    printf "\015\033[K[%d:%02d] Depth: %d" $rn_min $((rn_sec - 60*rn_min)) ${BASH_REMATCH[1]}
                elif [[ $REPLY =~ ^bestmove ]]; then
                    rn_res[time]=$SECONDS
                    break
                fi
            fi
        done
        echo -e "\e[?25h"  # Unhide cursor
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


ce_engine() {
    # USAGE: de_params DB $line $turn $side

    #local en_db=$1
    #local en_l=$2
    #local en_t=$3
    #local en_s=$4

    # Run engine
    local -A en_res
    local en_fen
    if [[ $LOC == office ]]; then
        # Simulate on laptop
        en_res[time]=15

        # Philidor $ eng
        en_fen="2kr3r/1pp1qpb1/p2pb1p1/4n2p/4PBP1/2N1QP1P/PPP1B3/1K1R3R w - - 5 17"
        en_res[1]="info depth 15 seldepth 23 multipv 1 score cp 115 nodes 11508520 nps 8998060 hashfull 5 tbhits 0 time 1279 pv f4g5 f7f6 g5h4 e5c6 a2a3 c8b8 f3f4 h5g4 h3g4 d8e8 h4f2 h8h1 d1h1 f6f5 g4f5 g6f5 h1h7 e6g8 c3d5"
        en_res[2]="info depth 15 seldepth 20 multipv 2 score cp 110 nodes 11508520 nps 8998060 hashfull 5 tbhits 0 time 1279 pv h1e1 e5c6 f4g5 f7f6 g5f4 h5g4 h3g4 e7f7 c3d5 d8e8 e3a3 f6f5 g4f5 g6f5 f4e3 f5e4 f3e4 h8h3"
        en_res[3]="info depth 15 seldepth 30 multipv 3 score cp 100 nodes 11508520 nps 8998060 hashfull 5 tbhits 0 time 1279 pv e3d4 e7f6 d4e3 f6e7 g4g5 e5c6 a2a3 c8b8 c3d5 e6d5 d1d5 g7e5 f4e5 d6e5 c2c3 f7f6 g5f6 e7f6"
        en_res[5]="info depth 15 seldepth 22 multipv 5 score cp 98 nodes 11508520 nps 8998060 hashfull 5 tbhits 0 time 1279 pv h1g1 h5g4 h3g4 c8b8 f4g5 f7f6 g5f4 e5c4 e3f2 d8e8 f4c1 e7d7 f3f4 f6f5 g4f5 g6f5 f2f1 d7f7"

        # Dutch 7b eng
        #en_fen="rnbq1rk1/pp2p1bp/2pp1np1/5p2/2PP4/2N2NP1/PP2PPBP/R1BQ1RK1 w - - 0 8"
        #en_res[1]="info depth 18 seldepth 27 multipv 1 score cp 165 nodes 42919235 nps 2880292 hashfull 38 tbhits 0 time 14901 pv d1b3 b8a6 f1d1 c6c5 b3c2 c8d7 a2a3 c5d4 f3d4 a6c5 b2b4 c5e4 g2e4 f5e4 c3e4 e7e5 d4b5 f6e4 c2e4"
        #en_res[2]="info depth 18 seldepth 24 multipv 2 score cp 164 nodes 42919235 nps 2880292 hashfull 38 tbhits 0 time 14901 pv d1c2 b8a6 f1d1 c8e6 b2b3 e6d7 c1g5 a6c7 e2e3 b7b5 g5f6 g7f6 c3e2 b5c4 b3c4 a8b8 h2h4 c7e6"
        #en_res[3]="info depth 18 seldepth 29 multipv 3 score cp 160 nodes 42919235 nps 2880292 hashfull 38 tbhits 0 time 14901 pv d1d3 b8a6 a2a3 a6c7 f1d1 c8d7 c1g5 a8b8 e2e3 b7b5 c4b5 c6b5 g5f6 g7f6 d3c2 f6g7 b2b4"
        #en_res[4]="info depth 18 seldepth 27 multipv 4 score cp 159 nodes 42919235 nps 2880292 hashfull 38 tbhits 0 time 14901 pv b2b3 e7e5 d4e5 d6e5 c1a3 d8d1 a1d1 f8e8 e2e4 a7a5 e4f5 c8f5 f1e1 e5e4 f3d4 b8a6 d4c2 a8d8 c2e3 d8d3 a3b2 a6c5"
        #en_res[5]="info depth 18 seldepth 27 multipv 5 score cp 148 nodes 42919235 nps 2880292 hashfull 38 tbhits 0 time 14901 pv c1e3 b8d7 d4d5 c6d5 c4d5 d7c5 a1c1 d8a5 a2a3 c5e4 f3g5 c8d7 g5e4 f6e4 e3d4 g7d4 d1d4 e4c3 c1c3 a5b6"

    else
        node_get $1 $2.$3.$4.f en_fen
        if ! ce_run "$en_fen" en_res; then
            GBL[ERR]=${en_res[err]}
            return 1
        fi
        GBL[ERR]="Analysis time: ${en_res[time]} secs."
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
    en_mvs=()
    local ii=1
    while [[ ${en_res[$ii]} =~ score\ cp\ ([0-9]+)\ .+\ pv\ (([a-h][1-8][a-h][1-8]\ )+) ]]; do
        en_scr=${BASH_REMATCH[1]}

        #e_debug "Processing #$ii"
        if ! ce_convert en_mvs "$en_fen" ${BASH_REMATCH[2]}; then
            return 1
        fi

        if [[ $ii == 1 ]]; then
            if ! cd_add_moves en_db $en_l en_tt en_ss "${en_mvs[@]}"; then
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
            if ! cd_branch_line en_db en_ll $en_l $en_tt $en_ss "${en_mvs[@]}"; then
                return 1
            fi
            # Add score to line comment
            node_get en_db $en_l.c en_tmp
            node_set en_db $en_ll.c "$en_tmp (score: $en_scr)"
        fi

        (( ii++ ))
    done

    # Add score to main line comment
    node_get en_db $en_l.c en_tmp
    node_set en_db $en_l.c "$en_tmp (score: $en_scr1)"

    # Save to dat/engine
    local en_file
    part -$ . "${GBL[DB_FILE]}" en_file
    part +$ / "$en_file" en_file
    en_file="${UTIL[DAT]}/engine/${en_file}_$2-$3-$4.dat"
    cd_save en_db "$en_file"

    # Launch results in new window
    cv_window "$en_file" $en_l.$en_tt.$en_ss
    return 0
}


<<'__NOTES__'

__NOTES__

# EOF
