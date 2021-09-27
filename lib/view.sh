#!/usr/bin/bash

# ANSI escape sequences
declare -A X=(
    [0]=$(make_es 0)

    [l]=$(make_es u)                # Line description
    [c]=$(make_es b y)              # Current move
    [#]=$(make_es bl)               # Comments
    [a]=$(make_es b)                # Alt move to main line

    [ww]=$(make_es '48;2;60;60;60')     # White piece on white square
    [bw]=$(make_es g '48;2;60;60;60')   # Black (green) piece on white square
    #[wb]=                              # White piece on black square
    [bb]=$(make_es g)                   # Black (green) piece on black square
)

cv_gen_board () {
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
        local -n gb_bb=$1
        gb_fen=${gb_bb[board]}
    fi
    local -n gb_brd=$2
    gb_brd=()

    # 64 squares
    local -A gb_sq
    local -a gb_rks
    local gb_fls
    case $gb_fmt in
        -a) # ANSI escape sequences
            if $FANCY_BOARD; then
                gb_sq=( # Empty white square
                        [w]="${X[ww]}   ${X[0]}"
                        # White pieces on white squares
                        [Kw]="${X[ww]} ♚ ${X[0]}" [Qw]="${X[ww]} ♛ ${X[0]}" [Rw]="${X[ww]} ♜ ${X[0]}"
                        [Bw]="${X[ww]} ♝ ${X[0]}" [Nw]="${X[ww]} ♞ ${X[0]}" [Pw]="${X[ww]} ♟ ${X[0]}"
                        # Black pieces on white squares
                        [kw]="${X[bw]} ♔ ${X[0]}" [qw]="${X[bw]} ♕ ${X[0]}" [rw]="${X[bw]} ♖ ${X[0]}"
                        [bw]="${X[bw]} ♗ ${X[0]}" [nw]="${X[bw]} ♘ ${X[0]}" [pw]="${X[bw]} ♙ ${X[0]}"
                        # Empty black square
                        [b]='   '
                        # White pieces on black squares
                        [Kb]=" ♚ " [Qb]=" ♛ " [Rb]=" ♜ "
                        [Bb]=" ♝ " [Nb]=" ♞ " [Pb]=" ♟ "
                        # Black pieces on black squares
                        [kb]="${X[bb]} ♔ ${X[0]}" [qb]="${X[bb]} ♕ ${X[0]}" [rb]="${X[bb]} ♖ ${X[0]}"
                        [bb]="${X[bb]} ♗ ${X[0]}" [nb]="${X[bb]} ♘ ${X[0]}" [pb]="${X[bb]} ♙ ${X[0]}" )
                if $gb_rot; then
                    gb_rks=('1 ' '2 ' '3 ' '4 ' '5 ' '6 ' '7 ' '8 ')
                    gb_fls='   h  g  f  e  d  c  b  a '
                else
                    gb_rks=('8 ' '7 ' '6 ' '5 ' '4 ' '3 ' '2 ' '1 ')
                    gb_fls='   a  b  c  d  e  f  g  h '
                fi
            else
                gb_sq=( [w]="${X[ww]}   ${X[0]}"
                        [Kw]="${X[ww]} K ${X[0]}" [Qw]="${X[ww]} Q ${X[0]}" [Rw]="${X[ww]} R ${X[0]}"
                        [Bw]="${X[ww]} B ${X[0]}" [Nw]="${X[ww]} N ${X[0]}" [Pw]="${X[ww]} P ${X[0]}"
                        [kw]="${X[bw]} K ${X[0]}" [qw]="${X[bw]} Q ${X[0]}" [rw]="${X[bw]} R ${X[0]}"
                        [bw]="${X[bw]} B ${X[0]}" [nw]="${X[bw]} N ${X[0]}" [pw]="${X[bw]} P ${X[0]}"
                        [b]='   '
                        [Kb]=" K " [Qb]=" Q " [Rb]=" R "
                        [Bb]=" B " [Nb]=" N " [Pb]=" P "
                        [kb]="${X[bb]} K ${X[0]}" [qb]="${X[bb]} Q ${X[0]}" [rb]="${X[bb]} R ${X[0]}"
                        [bb]="${X[bb]} B ${X[0]}" [nb]="${X[bb]} N ${X[0]}" [pb]="${X[bb]} P ${X[0]}" )
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
            gb_sq=( [w]=' '
                    [Kw]='K' [Qw]='Q' [Rw]='R' [Bw]='B' [Nw]='N' [Pw]='P'
                    [kw]='k' [qw]='q' [rw]='r' [bw]='b' [nw]='n' [pw]='p'
                    [b]=' '
                    [Kb]='K' [Qb]='Q' [Rb]='R' [Bb]='B' [Nb]='N' [Pb]='P'
                    [kb]='k' [qb]='q' [rb]='r' [bb]='b' [nb]='n' [pb]='p' )
            if $gb_rot; then
                gb_rks=('1|' '2|' '3|' '4|' '5|' '6|' '7|' '8|')
                gb_fls='  h g f e d c b a '
            else
                gb_rks=('8|' '7|' '6|' '5|' '4|' '3|' '2|' '1|')
                gb_fls='  a b c d e f g h '
            fi
            ;;
        -h) # HTML
            gb_sq=( [w]='<div class="white">&nbsp;</div>'
                    [Kw]='<div class="white">&#9812;</div>' [Qw]='<div class="white">&#9813;</div>' [Rw]='<div class="white">&#9814;</div>'
                    [Bw]='<div class="white">&#9815;</div>' [Nw]='<div class="white">&#9816;</div>' [Pw]='<div class="white">&#9817;</div>'
                    [kw]='<div class="white">&#9818;</div>' [qw]='<div class="white">&#9819;</div>' [rw]='<div class="white">&#9820;</div>'
                    [bw]='<div class="white">&#9821;</div>' [nw]='<div class="white">&#9822;</div>' [pw]='<div class="white">&#9823;</div>'
                    [b]='<div class="black">&nbsp;</div>'
                    [Kb]='<div class="black">&#9812;</div>' [Qb]='<div class="black">&#9813;</div>' [Rb]='<div class="black">&#9814;</div>'
                    [Bb]='<div class="black">&#9815;</div>' [Nb]='<div class="black">&#9816;</div>' [Pb]='<div class="black">&#9817;</div>'
                    [kb]='<div class="black">&#9818;</div>' [qb]='<div class="black">&#9819;</div>' [rb]='<div class="black">&#9820;</div>'
                    [bb]='<div class="black">&#9821;</div>' [nb]='<div class="black">&#9822;</div>' [pb]='<div class="black">&#9823;</div>' )
            # TODO - HTML board lacks rank numbers/file letters
            gb_rks=('<div class="chessboard">' '' '' '' '' '' '' '')
            gb_fls='</div>'
            ;;
    esac
                     # Starts from a8 which is white

    local gb_ch gb_sqs
    local gb_clr=w   # Color of square
    for gb_ch in $(echo $gb_fen | grep -o .); do
        case $gb_ch in
            /)
                if [[ $gb_clr == w ]]; then gb_clr=b; else gb_clr=w; fi
                ;;
            [1-8])
                while [[ $gb_ch -gt 0 ]]; do
                    gb_sqs+=("${gb_sq[$gb_clr]}")
                    if [[ $gb_clr == w ]]; then gb_clr=b; else gb_clr=w; fi
                    (( gb_ch-- ))
                done
                ;;
            *)
                gb_sqs+=("${gb_sq[$gb_ch$gb_clr]}")
                if [[ $gb_clr == w ]]; then gb_clr=b; else gb_clr=w; fi
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


cv_moves_and_board () {
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
                mb_fmt="%2s. ${X[c]}%-8s${X[0]}  %-8s  %s\n"
            else
                mb_fmt="%2s. %-8s  ${X[c]}%-8s${X[0]}  %s\n"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-8s  %-8s  %s\n"
        fi

        if [[ -n $mb_wmv || -n $mb_bmv ]]; then
            printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv" "${mb_bb[$ii]}"
        else
            echo "                        ${mb_bb[$ii]}"
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


cv_window () {
    # USAGE: cv_window [--readonly] "$file" $l.$t.$s

    local nw_ro=
    if [[ $1 == '--readonly' ]]; then
        nw_ro=$1
        shift
    fi

    #local nw_file=$1
    #local nw_start=$2

    local nw_debug=
    if ${UTIL[DEBUG]}; then
        nw_debug='-d'
    fi
    local nw_cmd=$(printf "$WINDOW_CMD" "$0 $nw_debug $nw_ro $1 -s $2")
    if $WINDOW_BKG; then
        $nw_cmd &
    else
        $nw_cmd
    fi
}


cv_enumerate_moves () {
    # USAGE: cv_enumerate_moves moves output [$turn [$side]]

    local -n em_moves=$1
    local -n em_out=$2
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
