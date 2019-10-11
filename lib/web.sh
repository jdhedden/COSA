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
__CSS__
}

cw_tail() {
    echo -e "</body>\n</html>"
}


cw_moves_list() {
    # USAGE: cw_moves_table DB $L moves
    #local mt_db=$1
    #local mt_l=$2
    eval "local -n mt_tbl=$3"

    # Gather moves
    local -a mt_mvs
    cd_gather_moves $1 mt_mvs $2

    local mt_x mt_t=1 mt_w
    local mt_fmt="<td>%s.</td><td><a href=\"/cosa.cgi?D=$D&L=$2&T=%s&S=w&R=$R\">%s</a></td><td><a href=\"/cosa.cgi?D=$D&L=$2&T=%s&S=b&R=$R\">%s</a></td>"
    local mt_fmt_w="<td>%s.</td><td><a href=\"/cosa.cgi?D=$D&L=$2&T=%s&S=w&R=$R\">%s</a></td><td>&nbsp;</td>"

    local ii
    for ii in "${mt_mvs[@]}"; do
        if [[ -z $mt_w ]]; then
            mt_w=$ii
        else
            printf -v mt_x "$mt_fmt" $mt_t $mt_t $mt_w $mt_t $ii
            mt_tbl+=("$mt_x")
            mt_w=
            ((mt_t++))
        fi
    done
    if [[ -n $mt_w ]]; then
        printf -v mt_x "$mt_fmt_w" $mt_t $mt_t $mt_w
        mt_tbl+=("$mt_x")
    fi
}

# EOF
