#!/bin/bash

# http://code2care.org/pages/chessboard-with-pieces-using-pure-html-and-css/

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
            if [[ $LOC == home ]]; then
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


cv_moves_table() {
    # TODO

    local mt_t mt_w mt_b
    local mt_fmt='<tr><td>%s.</td><td>%s</td><td>%s</td></tr>\n'

    echo '<table>'

    for item in "$@"; do
        if [[ -z $mt_t ]]; then
            if [[ $item =~ \.\.\.$ ]]; then
                mt_w='&#2026;'
            fi
            mt_t=${item//./}
        elif [[ -z $mt_w ]]; then
            mt_w=$item
        else
            printf "$mt_fmt" $mt_t $mt_w $mt_b
        fi
    done

    echo '</table>'
}


# test_web.sh
cv_gen_page() {
    # USAGE: cv_gen_page [-r] "$fen"|board ???
    # TODO

    local gp_rot
    if [[ $1 == -r ]]; then
        gp_rot=$1
        shift
    fi

    local gp_f
    if [[ $1 =~ / ]]; then
        local -a gp_ff=($1)
        $gp_f=${gp_ff[0]}
    else
        eval "local -n gp_bb=$1"
        $gp_f=${gp_bb[board]}
    fi

    eval "local -n gp_mvs=$2"  # ???

    cat <<'__HEAD__'
<html>
<head>
<meta charset="UTF-8">
<title>Chess</title>
<style type="text/css">
.chessboard {
    width: 320px;
    height: 320px;
    margin: 20px;
    border: 3px solid #888;
}
.black {
    float: left;
    width: 40px;
    height: 40px;
    background-color: #DDD;
    font-size:30px;
    text-align:center;
    display: table-cell;
    vertical-align:middle;
}
.white {
    float: left;
    width: 40px;
    height: 40px;
    background-color: #FFF;
    font-size:30px;
    text-align:center;
    display: table-cell;
    vertical-align:middle;
}
</style>
</head>
<body>
__HEAD__

    # Print board
    local gp_brd gp_txt
    cv_gen_board -h $gp_rot "$$gp_f" brd
    for gp_txt in "${gp_brd[@]}"; do
        echo "$gp_txt"
    done

    # Print moves
    #cv_moves_table

    # Close
    echo '</body></html>'
}


# test.sh
cv_boards_and_move() {
    eval "local -n bm_brd1=$1"
    eval "local -n bm_brd2=$2"
    local -a bm_mvs=("${@:3}")

    local ii
    for ii in 0 1 2 3 4 5 6 7 8; do
        printf "# %s  %-12s  %s\n" "${bm_brd1[$ii]}" "${bm_mvs[$ii]}" "${bm_brd2[$ii]}"
    done
}


# test.sh
cv_board_and_text() {
    eval "local -n bt_brd=$1"
    local -a bt_txt=("${@:2}")

    local ii
    for ii in 0 1 2 3 4 5 6 7 8; do
        printf "# %s   %s\n" "${bt_brd[$ii]}" "${bt_txt[$ii]}"
    done
}


# cosa.sh
cv_moves_and_board() {
    #local mb_db=$1
    #local mb_l=$2
    #local mb_t=$3
    #local mb_s=$4
    #local mb_rot=$5

    # Generate the current board
    local mb_f
    node_get $1 $2.$3.$4.f mb_f
    local -A mb_brd
    cm_set_board mb_brd "$mb_f"

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

    local mb_wmv mb_bmv
    local mb_tt=1;
    local done=

    while [[ -z $done || $ii -le 8 ]]; do
        if ! node_get -q $1 $2.$mb_tt.w.m mb_wmv; then
            if [[ $ii -gt 8 ]]; then break; fi
            mb_wmv=
        fi
        if ! node_get -q $1 $2.$mb_tt.b.m mb_bmv; then
            mb_bmv=
            done=true
        fi

        if [[ $mb_tt -eq $3 ]]; then
            # Display highlighted move
            if [[ $4 == w ]]; then
                mb_fmt="%2s. ${X[c]}%-5s${X[0]}  %-5s           %s\n"
            else
                mb_fmt="%2s. %-5s  ${X[c]}%-5s${X[0]}           %s\n"
            fi
        else
            # Display moves
            mb_fmt="%2s. %-5s  %-5s           %s\n"
        fi

        if [[ -n $mb_wmv || -n $mb_bmv ]]; then
            printf "$mb_fmt" $mb_tt "$mb_wmv" "$mb_bmv" "${mb_bb[$ii]}"
        else
            echo "                           ${mb_bb[$ii]}"
        fi
        (( ii++ ))

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
        for mb_mv in $(sorted "${!mb_a[@]}"); do
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

    local tmp=
    if ${UTIL[DEBUG]}; then
        tmp='-d'
    fi
    if [[ $LOC == home ]]; then
        xfce4-terminal --zoom=2 --geometry=56x58 -x $0 $tmp -w $1 -s $2
    elif [[ $LOC == office ]]; then
        /usr/bin/mintty -s 80,72 -e $0 $tmp -w $1 -s $2 &
    elif [[ $LOC == phone ]]; then
        $0 $tmp -s $line.$turn.$side -w ${GBL[DB_FILE]}
    else
        GBL[ERR]="Multiple windows feature is not supported on this platform: LOC='$LOC'"
    fi
}

<<'__NOTES__'

__NOTES__

# EOF
