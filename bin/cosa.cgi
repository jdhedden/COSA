#!/bin/bash

# Chess Opening Study Aid

# $COSA is set in cosa-ui
. $COSA/lib/utils
. $COSA/cfg/cfg.sh
. $COSA/lib/web.sh


<<__GBL__

Global Variables

  From URL:
    D = Encoded name of DB
    L, T, S = line, turn and side
    R = Rotate board

  Generated locally:
    DB_NAME = Decoded name of DB
    DB_FILE = Full path to DB
    DB = The loaded DB data
    SAVE_DB

__GBL__


show_dbs() {
    local -a dbs
    cd_list dbs

    if [[ ${#dbs[@]} -eq 0 ]]; then
        DB_NAME=Openings     # No DBs - use default
        D=$DB_NAME
        return 1
    elif [[ ${#dbs[@]} -eq 1 ]]; then
        DB_NAME=${dbs[0]}    # Only one DB
        D=$(busybox httpd -e "$DB_NAME")
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

    cw_head "$DB_NAME"

    cat <<__WEB__
Opening DB: $DB_NAME<br>
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
    cw_head

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

    local fen
    get_node DB $L.$T.$S.f fen

    declare -a brd
    cv_gen_board -h $rot $fen brd

    local ii
    for ii in "${brd[@]}"; do
        echo "$ii"
    done

    cw_tail
}


main() {
    local ii
    for ii in ${QUERY_STRING//&/ }; do
        eval "$ii"
    done

    # Get DB
    if [[ -z $D ]]; then
        if show_dbs; then
            return 0
        fi
    else
        DB_NAME=$(busybox httpd -d "$D")
    fi

    DB_FILE="$COSA/dat/$DB_NAME.dat"
    declare -A DB
    cd_load DB DB_FILE

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

    if db_fenify DB $L; then
        SAVE_DB=true
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
