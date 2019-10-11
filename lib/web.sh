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


cw_moves_table() {
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

# EOF
