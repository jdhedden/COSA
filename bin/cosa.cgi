#!/usr/bin/bash

# Chess Opening Study Aid

# $COSA is set in cosa-ui
. $COSA/lib/utils misc tree
. $COSA/cfg/cfg.sh
. $COSA/lib/web.sh


# Global Variables
<<'__URL__'
    D = Encoded name of DB
    L, T, S = line, turn and side
    R = Rotate board
__URL__
<<'__HERE__'
    DB = The loaded DB data
__HERE__


show_dbs () {
    local -a dbs
    cd_list dbs

    if [[ ${#dbs[@]} -eq 0 ]]; then
        GBL[DB_NAME]=Openings     # No DBs - use default
        D=${GBL[DB_NAME]}
        return 1
    elif [[ ${#dbs[@]} -eq 1 ]]; then
        GBL[DB_NAME]=${dbs[0]}    # Only one DB
        D=$(busybox httpd -e "${GBL[DB_NAME]}")
        return 1
    fi

    cw_head

    cat <<__WEB__
<table>
<tr><td><span style="font-size:125%"><b>Chess Opening Study Aid v$COSA_VERSION</b></span></td></tr>
<tr align="center"><td><b>COSA</b> - <i>It's a thing</i> ...</td></tr>
</table>
<br>Choose an opening DB:<ul>
__WEB__

    local db_name db
    for db_name in "${dbs[@]}"; do
        db=$(busybox httpd -e "$db_name")
        echo "<li><a href=\"/cosa.cgi?D=$db\">$db_name</a>"
    done
    echo '</ul>'

    cw_tail
    return 0
}


show_lines () {
    local -A lns
    cd_list_lines DB lns

    if [[ ${#lns[@]} -eq 0 ]]; then
        return 1    # No lines in DB
    elif [[ ${#lns[@]} -eq 1 ]]; then
        # Only one main line
        L=${lns[${!lns[@]}]}
        part +1 '|' "$L" L
        return 1
    fi

    cw_head "${GBL[DB_NAME]}"

    cat <<__WEB__
Opening DB: ${GBL[DB_NAME]}<br>
Which line?<ul>
__WEB__

    local ln ifs
    ifs=$IFS
    IFS=$'\n\r'
    for ln in $(sorted "${!lns[@]}"); do
        L=${lns[$ln]}
        echo "<li><a href=\"/cosa.cgi?D=$D&L=$L\">$ln</a>"
    done
    IFS=$ifs
    echo '</ul>'

    cw_tail
    return 0
}


new_line () {
    # TODO
    cw_head
    echo 'Empty database'
    cw_tail
    return 0
}


show_board () {
    # Output page
    cw_head "${GBL[DB_NAME]}"
    local cmt='&nbsp;'
    if node_exists DB $L.m; then cmt='!'; fi   # Main line of study
    echo "<h3>$cmt&nbsp;$(node_get -q DB $L.c)</h3>"

    # Rotate board?
    local rot
    node_get -q DB $L.r rot
    if [[ -n $R ]]; then
       if [[ -z $rot ]]; then
           rot=-r
       else
           rot=
       fi
    fi

    # Board
    local fen
    node_get DB $L.$T.$S.f fen
    declare -a brd
    cv_gen_board -h $rot "$fen" brd
    local ii
    for ii in "${brd[@]}"; do
        echo "$ii"
    done

    # Move's comment
    node_get DB $L.$T.$S.c cmt

    # Gather moves
    local -a moves
    cd_gather_moves DB moves $L

    # Nav bar
    echo '<table><tr>'
    local -A nav
    cw_nav moves nav
    echo '<table width="320">'
    echo "<tr><td>&nbsp;</td><td>${nav[prev]}&nbsp;&nbsp;${nav[rot]}&nbsp;&nbsp;${nav[next]}</td>"
    echo "<td align="right">${nav[line]}&nbsp${nav[sep]}&nbsp;${nav[db]}<td></tr>"
    echo '</table>'
    echo '</tr>'

    # Alts moves
    echo '<tr><table><tr>'
    local -a alts
    cw_alts alts
    if [[ ${#alts[@]} -gt 0 ]]; then
        echo -n "<td>Alts:&nbsp;&nbsp;$T."
        if [[ $S == b ]]; then
            echo -n '..'
        fi
        echo '&nbsp;</td>'
        for ii in "${alts[@]}"; do
            echo "$ii"
        done
    elif [[ -n $cmt ]]; then
        echo "<td><font color="008800">Cmt:</font> $cmt</td>"
        cmt=
    else
        echo -n '<td><font color="FFFFFF">No alts</font></td>'
    fi
    echo '</tr></table></tr>'

    # Move comment
    if [[ -n $cmt ]]; then
        echo "<tr><td><font color="00DD00">Cmt:</font> $cmt</td></tr>"
    fi

    # List of moves
    echo '<tr><td><span style="font-size:25%">&nbsp;</span></td></tr><tr><table>'
    local -a mvs_fmt
    cw_moves moves mvs_fmt
    if [[ ${#mvs_fmt[@]} -gt 30 ]]; then
        rows=$(( ( ${#mvs_fmt[@]} + 2 ) / 3 ))
    elif [[ ${#mvs_fmt[@]} -gt 10 ]]; then
        rows=10
    else
        rows=${#mvs_fmt[@]}
    fi
    for (( ii=0; ii<rows; ii++ )); do
        echo "<tr>${mvs_fmt[$ii]}${mvs_fmt[$((ii+rows))]}${mvs_fmt[$((ii+rows+rows))]}</tr>"
    done
    echo '</table></tr></table>'

    # Close page
    cw_tail
}


main () {
    local tmp
    for tmp in ${QUERY_STRING//&/ }; do
        eval "$tmp"
    done

    # Get DB
    if [[ -z $D ]]; then
        if show_dbs; then
            return 0
        fi
    else
        GBL[DB_NAME]=$(busybox httpd -d "$D")
    fi

    declare -A DB
    tmp="$COSA/dat/${GBL[DB_NAME]}.dat"
    cd_load DB tmp
    GBL[DB_FILE]="$tmp"

    # Get line, turn and side
    if [[ -z $L ]]; then
        if show_lines; then
            return 0
        fi
    fi

    if [[ -z $L ]]; then
        new_line
        return 0
    fi

    if [[ -z $T ]]; then
        if node_get -q DB $L.s T; then
            part +$ . $T S
            part +1 . $T T
        else
            T=1; S=w
        fi
    fi

    # Show board
    show_board
}


main
exit $?


<<'__NOTES__'

cv_gen_page '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page.html
cv_gen_page -r '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page2.html

__NOTES__

# EOF
