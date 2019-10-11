#!/bin/bash

# Chess Opening Study Aid

# $COSA is set in cosa-ui
. $COSA/lib/utils
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


show_dbs() {
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


show_lines() {
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

    local ln
    for ln in $(sorted "${!lns[@]}"); do
        part +1 '|' "${lns[$ln]}" L     # Line #
        part +$ '|' "${lns[$ln]}" ln    # Line name (comment)
        echo "<li><a href=\"/cosa.cgi?D=$D&L=$L\">$ln</a>"
    done
    echo '</ul>'

    cw_tail
    return 0
}


mt_db() {
    # TODO
    return 0
}


show_board() {
    # Name of line
    local cmt
    node_get -q DB $L.c cmt

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

    # Generate board
    local fen
    node_get DB $L.$T.$S.f fen
    declare -a brd
    cv_gen_board -h $rot "$fen" brd

    # Ouput page
    cw_head "${GBL[DB_NAME]}"

    echo "$cmt<br>"

    local ii
    for ii in "${brd[@]}"; do
        echo "$ii"
    done

    cw_tail
}


main() {
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
        mt_db
        return 0
    fi

    local save_db=false
    if cd_fenify DB $L; then
        save_db=true
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

    # Write DB changes to disk
    if $save_db; then
        cd_save DB "${GBL[DB_FILE]}"
    fi
}


main
exit $?


<<'__NOTES__'

cv_gen_page '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page.html
cv_gen_page -r '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page2.html

__NOTES__

# EOF
