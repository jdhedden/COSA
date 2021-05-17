#!/usr/bin/bash

# http://code2care.org/pages/chessboard-with-pieces-using-pure-html-and-css/

cw_head () {
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
#alt { color: green; }
</style>
</head>
<body>
__CSS__
}

cw_tail () {
    echo -e "</body>\n</html>"
}

cw_cell () {
    # USAGE: cw_cell_link -n -p -s 'style' -a 'attr' D L T S R 'content'
    #                                                1 2 3 4 5  6
    local cl_cell=true
    local cl_pad=''
    local cl_style=''
    local cl_css=''
    while [[ $1 =~ ^- ]]; do
        case $1 in
            -n)
                cl_cell=false
                ;;
            -p)
                cl_pad='&nbsp;'
                ;;
            -s)
                cl_style=" $2"
                shift
                ;;
            -a)
                cl_css=" id=\"$2\""
                shift
                ;;
        esac
        shift
    done
        
    if $cl_cell; then
        echo "<td$cl_style>$cl_pad<a${cl_css} href=\"/cosa.cgi?D=$1&L=$2&T=$3&S=$4&R=$5\">$6</a></td>"
    else
        echo "<a${cl_css} href=\"/cosa.cgi?D=$1&L=$2&T=$3&S=$4&R=$5\">$6</a>"
    fi
}


cw_nav () {
    # USAGE: cw_nav nav mvs_fmt
    local -n nv_mvs=$1
    local -n nv_nav=$2

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


cw_alts () {
    # USAGE: cw_alts alts
    local -n am_a=$1
    local -A am_aa
    local am_mv
    if cd_get_alts DB $L $T $S am_aa; then
        for am_mv in "${!am_aa[@]}"; do
            if node_exists DB ${am_aa[$am_mv]}.m; then
                am_a+=("$(cw_cell -p -s 'bgcolor="#DDD"' $D ${am_aa[$am_mv]} $T $S "$R" "$am_mv")")
            else
                am_a+=("$(cw_cell -p $D ${am_aa[$am_mv]} $T $S "$R" "$am_mv")")
            fi
        done
    fi
}

cw_moves () {
    # USAGE: cw_moves moves mvs_fmt
    local -n fm_mvs=$1
    local -n fm_mvf=$2
    fm_mvf=()

    # Format moves
    local fm_t=1 fm_idx=0
    local fm_w=$(cw_cell -p $D $L %s w "$R" %s) fm_ww
    local fm_b=$(cw_cell -p $D $L %s b "$R" %s) fm_bb
    local fm_wa=$(cw_cell -p -a alt $D $L %s w "$R" %s)
    local fm_ba=$(cw_cell -p -a alt $D $L %s b "$R" %s)
    while [[ $fm_idx -lt ${#fm_mvs[@]} ]]; do
        if node_is_node DB $L.$fm_t.w.a; then
            printf -v fm_ww "$fm_wa" $fm_t "${fm_mvs[$fm_idx]}"
        else
            printf -v fm_ww "$fm_w" $fm_t "${fm_mvs[$fm_idx]}"
        fi
        if node_is_node DB $L.$fm_t.b.a; then
            printf -v fm_bb "$fm_ba" $fm_t "${fm_mvs[$((fm_idx+1))]}"
        else
            printf -v fm_bb "$fm_b" $fm_t "${fm_mvs[$((fm_idx+1))]}"
        fi
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
