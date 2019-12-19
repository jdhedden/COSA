#!/bin/bash

# ANSI escape sequences
declare -A X=(
    [0]=$(make_es 0)
    [l]=$(make_es u)                # Line description
    [c]=$(make_es b y)              # Current move
    [q]=$(make_es '48;2;48;48;48')  # White sQuare background
    [w]=''                          # White pieces
    [b]=$(make_es g)                # Black pieces
    [#]=$(make_es bl)               # Comments
    [a]=$(make_es b)                # Alt move to main line
)

cv_gen_board() {
    # USAGE: cv_gen_board [-a|-t|-h] [-r] "$fen"|board varname

    local gb_fmt='-a'
    local gb_rot=false
    while : ; do
        case $1 in
            -[ath])
                gb_fmt=$1
                shift
                ;;
            -r)
                gb_rot=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    if [[ $gb_fmt == -a && ! -t 1 ]]; then
        gb_fmt='-t'   # Text only if not a terminal
    fi

    local gb_fen
    if [[ $1 =~ / ]]; then
        local -a gb_ff=($1)
        gb_fen=${gb_ff[0]}
    else
        eval "local -n gb_bb=$1"
        gb_fen=${gb_bb[board]}
    fi
    eval "local -n gb_brd=$2"; gb_brd=()

    # 64 squares
    local -a gb_sq_fmt
    local -A gb_pcs
    local -a gb_rks
    local gb_fls
    case $gb_fmt in
        -a) # ANSI escape sequences
            if $FANCY_BOARD; then
                gb_sq_fmt=( " %s ${X[0]}" "${X[q]} %s ${X[0]}" )
                gb_pcs=( [K]="${X[w]}♔" [Q]="${X[w]}♕" [R]="${X[w]}♖"
                        [B]="${X[w]}♗" [N]="${X[w]}♘" [P]="${X[w]}♙"
                        [k]="${X[b]}♚" [q]="${X[b]}♛" [r]="${X[b]}♜"
                        [b]="${X[b]}♝" [n]="${X[b]}♞" [p]="${X[b]}♟" )
                if $gb_rot; then
                    gb_rks=('1 ' '2 ' '3 ' '4 ' '5 ' '6 ' '7 ' '8 ')
                    gb_fls='   h  g  f  e  d  c  b  a '
                else
                    gb_rks=('8 ' '7 ' '6 ' '5 ' '4 ' '3 ' '2 ' '1 ')
                    gb_fls='   a  b  c  d  e  f  g  h '
                fi
            else
                gb_sq_fmt=( "%s${X[0]}|" "${X[q]}%s${X[0]}|" )
                gb_pcs=( [K]="${X[w]}K" [Q]="${X[w]}Q" [R]="${X[w]}R"
                        [B]="${X[w]}B" [N]="${X[w]}N" [P]="${X[w]}p"
                        [k]="${X[b]}K" [q]="${X[b]}Q" [r]="${X[b]}R"
                        [b]="${X[b]}B" [n]="${X[b]}N" [p]="${X[b]}p" )
                if $gb_rot; then
                    gb_rks=('1|' '2|' '3|' '4|' '5|' '6|' '7|' '8|')
                    gb_fls='  h g f e d c b a '
                else
                    gb_rks=('8|' '7|' '6|' '5|' '4|' '3|' '2|' '1|')
                    gb_fls='  a b c d e f g h '
                fi
            fi
            ;;
        -t) # Plain text
            gb_sq_fmt=( '%s|' '%s|' )
            gb_pcs=( [K]='K' [Q]='Q' [R]='R' [B]='B' [N]='N' [P]='P'
                    [k]='k' [q]='q' [r]='r' [b]='b' [n]='n' [p]='p' )
            if $gb_rot; then
                gb_rks=('1|' '2|' '3|' '4|' '5|' '6|' '7|' '8|')
                gb_fls='  h g f e d c b a '
            else
                gb_rks=('8|' '7|' '6|' '5|' '4|' '3|' '2|' '1|')
                gb_fls='  a b c d e f g h '
            fi
            ;;
        -h) # HTML
            gb_sq_fmt=( '<div class="black">%s</div>'
                     '<div class="white">%s</div>' )
            gb_pcs=( [K]='&#9812;' [Q]='&#9813;' [R]='&#9814;'
                    [B]='&#9815;' [N]='&#9816;' [P]='&#9817;'
                    [k]='&#9818;' [q]='&#9819;' [r]='&#9820;'
                    [b]='&#9821;' [n]='&#9822;' [p]='&#9823;' )
            # TODO - HTML board lacks rank numbers/file letters
            gb_rks=('<div class="chessboard">' '' '' '' '' '' '' '')
            gb_fls='</div>'
            ;;
    esac
    local gb_clr=0   # 0 = black square; 1 = white square
                   # Starts from a8 which is black

    local gb_ch gb_sq gb_sqs
    for gb_ch in $(echo $gb_fen | grep -o .); do
        case $gb_ch in
            /)
                gb_clr=$(( (gb_clr+1)%2 ))
                ;;
            [1-8])
                while [[ $gb_ch -gt 0 ]]; do
                    printf -v gb_sq "${gb_sq_fmt[gb_clr]}" ' '
                    gb_sqs+=("$gb_sq")
                    gb_clr=$(( (gb_clr+1)%2 ))
                    (( gb_ch-- ))
                done
                ;;
            *)
                printf -v gb_sq "${gb_sq_fmt[gb_clr]}" "${gb_pcs[$gb_ch]}"
                gb_sqs+=("$gb_sq")
                gb_clr=$(( (gb_clr+1)%2 ))
                ;;
        esac
    done

    local idx ii jj gb_txt

    if $gb_rot; then idx=63; else idx=0; fi

    for ii in {0..7}; do
        gb_txt="${gb_rks[$ii]}"
        for jj in {0..7}; do
            gb_txt+="${gb_sqs[$idx]}"
            if $gb_rot; then
                (( idx-- ))
            else
                (( idx++ ))
            fi
        done
        gb_brd+=("$gb_txt")
    done
    gb_brd+=("$gb_fls")
}


cv_moves_and_board() {
    #local mb_db=$1
    #local mb_l=$2
    #local mb_t=$3
    #local mb_s=$4
    #local mb_rot=$5

    # Generate the current board
    local mb_x
    node_get $1 $2.$3.$4.f mb_x
    local -A mb_brd
    cm_set_board mb_brd "$mb_x"

    # Header
    if ${UTIL[DEBUG]}; then
        echo -e "\n=====\n"
    else
        clear
    fi
    local mb_mn=''
    if node_exists $1 $2.m; then
        mb_mn='! '   # Main line of study
    fi
    local mb_c
    if node_get $1 $2.c mb_c; then
        echo -e "$mb_mn${X[l]}$mb_c${X[0]}\n"
    else
        echo -e "${mb_mn}Line #$2\n"
    fi

    # Rotate board?
    local mb_rr
    node_get -q $1 $2.r mb_rr
    if $5; then
       if [[ -z $mb_rr ]]; then
           mb_rr=-r
       else
           mb_rr=
       fi
    fi

    # Board and moves
    local -a mb_bb
    cv_gen_board $mb_rr -a mb_brd mb_bb
    local mb_fmt ii=0

    local mb_wmv mb_bmv mb_wmv2 mb_bmv2
    local mb_tt=1 mb_tt2 mb_last
    local done=

    # Move wrap
    cm_last $1 $2 mb_last mb_x
    if [[ $mb_last -gt 21 ]]; then
        if [[ $cm_last -gt 31 ]]; then
            mb_tt2=$(( mb_last / 2 + 7 ))
        else
            mb_tt2=22
        fi
    fi

    while [[ $ii -le 8 ]]; do
        if ! node_get -q $1 $2.$mb_tt.w.m mb_wmv; then
            mb_wmv=
        fi
        if ! node_get -q $1 $2.$mb_tt.b.m mb_bmv; then
            mb_bmv=
        fi

        if [[ $mb_tt -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt="%2s. ${X[c]}%-8s${X[0]}  %-8s     %s\n"
            else
                mb_fmt="%2s. %-8s  ${X[c]}%-8s${X[0]}     %s\n"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-8s  %-8s     %s\n"
        fi

        if [[ -n $mb_wmv || -n $mb_bmv ]]; then
            printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv" "${mb_bb[$ii]}"
        else
            echo "                           ${mb_bb[$ii]}"
        fi
        (( ii++ ))
        (( mb_tt++ ))
    done

    while [[ $mb_tt -le 11 || ( -z $mb_tt2 && $mb_tt -le 21 ) ]]; do
        if ! node_get -q $1 $2.$mb_tt.w.m mb_wmv; then
            break
        fi
        if ! node_get -q $1 $2.$mb_tt.b.m mb_bmv; then
            mb_bmv=
        fi

        if [[ $mb_tt -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt="%2s. ${X[c]}%-8s${X[0]}  %-8s\n"
            else
                mb_fmt="%2s. %-8s  ${X[c]}%-8s${X[0]}\n"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-8s  %-8s\n"
        fi

        printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv"
        (( mb_tt++ ))
    done

    while [[ -n $mb_tt2 && $mb_tt2 -le $mb_last ]]; do
        node_get -q $1 $2.$mb_tt.w.m mb_wmv
        node_get -q $1 $2.$mb_tt.b.m mb_bmv
        node_get -q $1 $2.$mb_tt2.w.m mb_wmv2
        if ! node_get -q $1 $2.$mb_tt2.b.m mb_bmv2; then
            mb_bmv2=
        fi

        if [[ $mb_tt -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt="%2s. ${X[c]}%-8s${X[0]}  %-8s"
            else
                mb_fmt="%2s. %-8s  ${X[c]}%-8s${X[0]}"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-8s  %-8s"
        fi

        if [[ $mb_tt2 -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt+="  %2s. ${X[c]}%-8s${X[0]}  %-8s\n"
            else
                mb_fmt+="  %2s. %-8s  ${X[c]}%-8s${X[0]}\n"
            fi
        else
            # Display moves
            mb_fmt+="  %2s. %-8s  %-8s\n"
        fi

        printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv" $mb_tt2 "$mb_wmv2" "$mb_bmv2"
        (( mb_tt++ ))
        (( mb_tt2++ ))
    done

    while [[ $mb_tt -le 21 ]]; do
        if ! node_get -q $1 $2.$mb_tt.w.m mb_wmv; then
            break
        fi
        if ! node_get -q $1 $2.$mb_tt.b.m mb_bmv; then
            mb_bmv=
        fi

        if [[ $mb_tt -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt="%2s. ${X[c]}%-8s${X[0]}  %-8s\n"
            else
                mb_fmt="%2s. %-8s  ${X[c]}%-8s${X[0]}\n"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-8s  %-8s\n"
        fi

        printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv"
        (( mb_tt++ ))
    done

    local one_echo=true
    if node_get -q $1 $2.$3.$4.c cmt; then
        echo -e "\n${X[#]}$cmt${X[0]}"
        one_echo=false
    fi

    # Display alt moves
    local -A mb_a
    if cd_get_alts $1 $2 $3 $4 mb_a; then
        if $one_echo; then
            echo
            one_echo=false
        fi
        echo -en "Alternate lines:\n  $3."
        if [[ $4 == b ]]; then echo -n '..'; fi
        local mb_mv
        for mb_mv in "${!mb_a[@]}"; do
            if node_exists $1 ${mb_a[$mb_mv]}.m; then
                echo -n " ${X[a]}$mb_mv${X[0]}"
            else
                echo -n " $mb_mv"
            fi
        done
        echo
    fi
}


cv_window() {
    # USAGE: cv_window "$file" $l.$t.$s

    #local nw_file=$1
    #local nw_start=$2

    local nw_debug=
    if ${UTIL[DEBUG]}; then
        nw_debug='-d'
    fi
    local nw_cmd=$(printf "$WINDOW_CMD" "$0 $nw_debug -w $1 -s $2")
    if $WINDOW_BKG; then
        $nw_cmd &
    else
        $nw_cmd
    fi
}

cv_enumerate_moves() {
    # USAGE: cv_enumerate_moves moves output [$turn [$side]]

    eval "local -n em_moves=$1"
    eval "local -n em_out=$2"
    #local em_start=$3 [e.g., 5 or 5w or 5b]
    #local em_side=$4  [e.g., w or b]
    local em_t=1 em_s=w em_m

    if [[ $3 =~ ^([0-9]+)(\.?([bw]))? ]]; then
        em_t=${BASH_REMATCH[1]}
        if [[ -z ${BASH_REMATCH[3]} ]]; then
            em_s=${4:-w}
        else
            em_s=${BASH_REMATCH[3]}
        fi
    fi
    if [[ $em_s == 'w' ]]; then
        em_out=''
    else
        em_out=" $em_t..."
    fi
    for em_m in "${em_moves[@]}"; do
        if [[ $em_s == 'w' ]]; then
            em_out+=" $em_t. $em_m"
            em_s='b'
        else
            em_out+=" $em_m"
            (( em_t++ ))
            em_s='w'
        fi
    done
}
# EOF
