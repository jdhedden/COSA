#!/bin/bash

# http://code2care.org/pages/chessboard-with-pieces-using-pure-html-and-css/

cw_head() {
    # USAGE: cs_head title
    cat <<__CSS__
<html>
<head>
<meta charset="UTF-8">
<title>$@</title>
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


cw_gen_page() {
    # USAGE: cw_gen_page [-r] "$fen"|board ???
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

    # Print board
    local gp_brd gp_txt
    cw_gen_board -h $gp_rot "$$gp_f" brd
    for gp_txt in "${gp_brd[@]}"; do
        echo "$gp_txt"
    done

    # Print moves
    #cw_moves_table

    # Close
    echo '</body></html>'
}


# EOF
