#!/bin/bash

# http://code2care.org/pages/chessboard-with-pieces-using-pure-html-and-css/

cw_head() {
    # USAGE: cs_head title
    cat <<__CSS__
Content-Type: text/html

<html>
<head>
<title>${1:-Welcome to COSA!}</title>
<meta charset="UTF-8">
<meta name="viewport" content="width=1280, initial-scale=1.0">
<style type="text/css">
.chessboard {
  width: 320px;
  height: 320px;
  margin: 10px;
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
a {
  color: blue;
  text-decoration: none;
}
</style>
</head>
<body>
__CSS__
}

cw_tail() {
    echo -e "</body>\n</html>"
}

cw_cell() {
    # USAGE: cw_cell_link -n D L T S R 'content' ['pad' ['style']]
    #                        1 2 3 4 5  6          7      8
    if [[ $1 == -n ]]; then
        shift
        echo "<a href=\"/cosa.cgi?D=$1&L=$2&T=$3&S=$4&R=$5\">$6</a>"
    else
        echo "<td $8>$7<a href=\"/cosa.cgi?D=$1&L=$2&T=$3&S=$4&R=$5\">$6</a>$7</td>"
    fi
}


cw_nav() {
    # USAGE: cw_nav nav mvs_fmt
    eval "local -n nv_mvs=$1"
    eval "local -n nv_nav=$2"

    # Rotate board
    if [[ -z $R ]]; then
        nv_nav[rot]=$(cw_cell -n $D $L $T $S '1' '&#8635')
    else
        nv_nav[rot]=$(cw_cell -n $D $L $T $S '' '&#8635')
    fi

    # Previous move
    local nv_t=$T nv_s=$S
    if cm_next -b DB $L nv_t nv_s; then
        nv_nav[prev]=$(cw_cell -n $D $L $nv_t $nv_s "$R" '&#10237')
    else
        nv_nav[prev]='<font color="FFFFFF">&#10237;</font>'
    fi

    # Next move
    nv_t=$T nv_s=$S
    if cm_next DB $L nv_t nv_s; then
        nv_nav[next]=$(cw_cell -n $D $L $nv_t $nv_s "$R" '&#10238')
    else
        nv_nav[next]='<font color="FFFFFF">&#10238;</font>'
    fi

    # DBs
    local -a nv_dbs
    cd_list nv_dbs
    if [[ ${#nv_dbs[@]} -gt 1 ]]; then
        nv_nav[db]=$(cw_cell -n '' '' '' '' '' 'DBs')
    else
        nv_nav[db]='<font color="FFFFFF">DBs</font>'
    fi

    # Lines
    local -A nv_lns
    cd_list_lines DB nv_lns
    if [[ ${#nv_lns[@]} -gt 1 ]]; then
        nv_nav[line]=$(cw_cell -n $D '' '' '' '' 'Lines')
    else
        nv_nav[line]='<font color="FFFFFF">Lines</font>'
    fi

    if [[ ${#nv_dbs[@]} -gt 1 && ${#nv_lns[@]} -gt 1 ]]; then
        nav[sep]='|'
    else
        nav[sep]='&nbsp;'
    fi
}


cw_alts() {
    # USAGE: cw_alts alts
    eval "local -n am_a=$1"
    local -A am_aa
    local am_mv
    if cd_get_alts DB $L $T $S am_aa; then
        for am_mv in "${!am_aa[@]}"; do
            if node_exists DB ${am_aa[$am_mv]}.m; then
                am_a+=("$(cw_cell $D ${am_aa[$am_mv]} $T $S "$R" "$am_mv" '&nbsp;' "bgcolor=\"#DDD\"")")
            else
                am_a+=("$(cw_cell $D ${am_aa[$am_mv]} $T $S "$R" "$am_mv" '&nbsp;')")
            fi
        done
    fi
}

cw_moves() {
    # USAGE: cw_moves moves mvs_fmt
    eval "local -n fm_mvs=$1"
    eval "local -n fm_mvf=$2"
    fm_mvf=()

    # Format moves
    local fm_t=1 fm_idx=0
    local fm_w=$(cw_cell $D $L %s w "$R" %s "&nbsp;") fm_ww
    local fm_b=$(cw_cell $D $L %s b "$R" %s "&nbsp;") fm_bb
    while [[ $fm_idx -lt ${#fm_mvs[@]} ]]; do
        printf -v fm_ww "$fm_w" $fm_t "${fm_mvs[$fm_idx]}"
        printf -v fm_bb "$fm_b" $fm_t "${fm_mvs[$((fm_idx+1))]}"
        if [[ $fm_t -eq $T ]]; then   # Highlight current move
            if [[ $S == w ]]; then
                fm_ww="<td bgcolor=\"#DDD\">&nbsp;${fm_mvs[$fm_idx]}</td>"
            else
                fm_bb="<td bgcolor=\"#DDD\">&nbsp;${fm_mvs[$((fm_idx+1))]}</td>"
            fi
        fi
        fm_mvf+=("<td>&nbsp;&nbsp;$fm_t.</td>$fm_ww$fm_bb")
        ((fm_t++))
        fm_idx=$(( (fm_t-1)*2 ))
    done
}

# EOF
