#!/bin/bash

cd_list() {
    eval "local -n ld_dbs=$1"
    #local ld_f=$2

    ld_dbs=()
    local ii
    for ii in $COSA/dat/$2*.dat; do
        if [[ ! -f $ii ]]; then break; fi
        part +$ / "$ii" ii
        part +1 . "$ii" ii
        ld_dbs+=("$ii")
    done
    for ii in $COSA/dat/engine/$2*.dat; do
        if [[ ! -f $ii ]]; then break; fi
        part +$ / "$ii" ii
        part +1 . "$ii" ii
        ld_dbs+=("engine/$ii")
    done
    return 0
}


cd_choose() {
    eval "local -n cd_f=$1"

    if [[ -n $cd_f && -f $COSA/dat/$cd_f.dat ]]; then
        cd_f=$COSA/dat/$cd_f.dat
        return 0
    fi

    local -a cd_dbs
    cd_list cd_dbs $cd_f

    if [[ ${#cd_dbs[@]} -eq 0 ]]; then
        if [[ -z $cd_f ]]; then
            cd_f=$COSA/dat/Openings.dat  # default
        else
            cd_f=$COSA/dat/$cd_f.dat     # new
        fi
        return 1   # Is a new DB

    elif [[ ${#cd_dbs[@]} -eq 1 ]]; then
        cd_f=$COSA/dat/${cd_dbs[0]}.dat   # Only one DB

    else
        echo
        PS3='
Which opening DB? '
        ii=
        while [[ -z $ii ]]; do
            select ii in '<Cancel>' "${cd_dbs[@]}"; do
                if [[ -n $ii ]]; then
                    break
                fi
            done
        done
        if [[ $ii == '<Cancel>' ]]; then
            cd_f=
            return 1
        fi
        cd_f=$COSA/dat/$ii.dat
    fi
    return 0   # Not a new DB
}


cd_load() {
    # USAGE: cd_load DB [file]
    eval "local -n ld_db=$1"
    eval "local -n ld_f=$2"
    if [[ -z $3 ]]; then
        local ld_u
    else
        eval "local -n ld_u=$3"
    fi

    local ii

    if [[ -z $ld_f || ! -f $ld_f ]]; then
        if ! cd_choose $2; then
            if [[ -z $ld_f ]]; then return 1; fi
            tree_init $1
            ld_u=true
            return 0
        fi
    fi

    while read; do
        if [[ $REPLY =~ (\[.+\]=.+$) ]]; then
            eval "ld_db${BASH_REMATCH[0]}"
        fi
    done <$ld_f
    return 0
}


cd_delete() {
    eval "local -n rm_f=$1"

    if cd_choose $1; then
        rm -f $rm_f
        return 0
    fi
    return 1
}


cd_save() {
    # USAGE: cd_save DB [$file]
    #local sd_db=$1
    local sd_f=$(realpath $2)

    if [[ -f $sd_f ]]; then
        local sd_n sd_e
        part +$ / "$sd_f" sd_n
        part +$ . "$sd_n" sd_e
        part -$ . "$sd_n" sd_n
        mkdir -p "$COSA/dat/_archive"
        mv "$sd_f" "$COSA/dat/_archive/${sd_n}_$(date '+%Y%m%d_%H%M%S').$sd_e"
    fi

    {   echo -e '#!/bin/bash\n'
        tree_dump $1
        echo -e '\n#EOF'
    } >$sd_f
}

#####

cd_fenify() {
    # USAGE: cd_fenify DB $line [force]
    #local fl_db=$1
    #local fl_l=$2

    local fl_t=1 fl_s=w fl_f

    # Step through moves until we find an unprocessed move
    if [[ -z $3 ]]; then
        while node_exists $1 $2.$fl_t.$fl_s.f; do
            node_get $1 $2.$fl_t.$fl_s.f fl_f
            if ! cm_next $1 $2 fl_t fl_s; then
                return 1   # All FEN-ified
            fi
        done
    fi

    local -A fl_bd
    cm_set_board fl_bd "$fl_f"

    # Process remaining moves
    local fl_mv fl_upd=false
    while node_get -q $1 $2.$fl_t.$fl_s.m fl_mv; do
        if ! cm_move fl_bd "$fl_mv"; then
            GBL[ERR]="Failed to fenify: l=$2 t=$fl_t s=$fl_s m=$fl_mv '${fl_bd[err]}'"
            return 1
        fi
        node_set $1 $2.$fl_t.$fl_s.f "${fl_bd[fen]}"
        fl_upd=true
        cm_next -f $1 $2 fl_t fl_s
    done
    if $fl_upd; then
        node_set $1 $2.t $(date +%s)
        return 0
    fi
    return 1
}

cd_refenify() {
    # USAGE: cd_refenify DB
    #local rf_db=$1

    for rf_l in $(node_get -q $1); do
        e_info $(node_get $1 $rf_l.c)
        part +$ . $rf_l rf_l
        cd_fenify $1 $rf_l force
    done
}

#####

cd_list_lines() {
    eval "local -n ll_db=$1"
    eval "local -n ll_lns=$2"

    local ll_l ll_c
    for ll_l in $(node_get -q $1); do
        if [[ -v "ll_db[$ll_l.m]" ]]; then
            part +$ . $ll_l ll_l
            node_get $1 $ll_l.c ll_c
            ll_lns[$ll_c]=$ll_l
        fi
    done
    return 0
}

cd_choose_line() {
    # USAGE: cd_choose_line [-n] DB line turn side count

    # Present '<New Line>' choice (detected using [[ $count -eq -1 ]])
    local new=false
    if [[ $1 == '-n' ]]; then
        new=true
        shift
    fi

    eval "local -n cl_db=$1"
    eval "local -n cl_l=$2"
    eval "local -n cl_t=$3"
    eval "local -n cl_s=$4"
    eval "local -n cl_n=$5"

    local -A cl_lns
    cd_list_lines $1 cl_lns
    cl_n=${#cl_lns[@]}

    if [[ ${#cl_lns[@]} -eq 0 ]]; then
        if $new; then
            cl_n=-1
        fi
        return 1
    elif [[ ${#cl_lns[@]} -eq 1 ]]; then
        cl_l=${cl_lns[${!cl_lns[@]}]}   # Only one line
        part +1 '|' "$cl_l" cl_l
    else
        cl_l=
    fi

    if $new; then
        cl_lns['<New Line>']=-1
    fi

    echo
    local cl_ifs
    PS3='
Which line? '
    while [[ -z $cl_l ]]; do
        cl_ifs=$IFS
        IFS=$'\n\r'
        select cl_x in $(sorted "${!cl_lns[@]}"); do
            if [[ -n $cl_x ]]; then
                if [[ $cl_x == '<New Line>' ]]; then
                    cl_n=-1
                    IFS=$cl_ifs
                    return 1
                fi
                cl_l=${cl_lns[$cl_x]}
                break
            fi
        done
        IFS=$cl_ifs
    done

    if node_get -q $1 $cl_l.s cl_x; then
        part +1 . $cl_x $3
        part +$ . $cl_x $4
    else
        cl_t=1; cl_s=w
    fi
    return 0
}

cd_main() {
    eval "local -n ml_db=$1"
    eval "local -n ml_l=$2"
    eval "local -n ml_t=$3"
    eval "local -n ml_s=$4"

    local -A ml_lns
    cd_cluster $1 ml_lns
    if [[ ${ml_lns[$ml_l]} -eq $ml_l ]]; then
        GBL[ERR]='Already on main line'
        return 1
    fi
    ml_l=${ml_lns[$ml_l]}
    local ml_x
    if node_get -q $1 $ml_l.s ml_x; then
        part +1 . $ml_x $3
        part +$ . $ml_x $4
    else
        ml_t=1; ml_s=w
    fi
    return 0
}

#####

cd_get_alts() {
    # USAGE: cd_get_alts DB $line $turn $move alts

    eval "local -n ga_db=$1"
    #local ga_l=$2
    #local ga_t=$3
    #local ga_s=$4
    eval "local -n ga_a=$5"

    local ga_mv ga_cnt=0
    for ga_mv in $(node_get -q $1 $2.$3.$4.a); do
        ga_a[$(part +$ . $ga_mv)]=${ga_db[$ga_mv]}
        (( ga_cnt++ ))
    done
    if [[ $ga_cnt -eq 0 ]]; then
        return 1
    fi
    return 0
}

cd_copy_alts() {
    # USAGE: cd_copy_alts DB $line1 $line2 $turn $side

    #local _db=$1
    #local ca_l1=$2
    #local ca_l2=$3
    #local ca_t=$4
    #local ca_s=$5

    local -A ca_a
    local ca_tt=1 ca_ss=w ca_m
    while [[ $ca_tt -lt $4 || \
           ( $ca_tt -eq $4 && $ca_ss == w && $5 == b ) ]]
    do
        if cd_get_alts $1 $2 $ca_tt $ca_ss ca_a; then
            for ca_m in "${!ca_a[@]}"; do
                node_set $1 $3.$ca_tt.$ca_ss.a.$ca_m "${ca_a[$ca_m]}"
            done
            ca_a=()
        fi
        cm_next -f $1 $2 ca_tt ca_ss
    done
}

cd_link_lines() {
    # USAGE: cd_link_lines DB $line1 $line2 $turn $side

    #local _db=$1
    #local ll_l1=$2
    #local ll_l2=$3
    #local ll_t=$4
    #local ll_s=$5

    local -A ll_a
    local ll_m
    cd_get_alts $1 $2 $4 $5 ll_a
    node_get $1 $2.$4.$5.m ll_m
    ll_a[$ll_m]=$2
    node_get $1 $3.$4.$5.m ll_m
    ll_a[$ll_m]=$3

    # Set alts in all related lines for this move
    local ll_ll ll_l
    for ll_ll in "${ll_a[@]}"; do
        for ll_m in "${!ll_a[@]}"; do
            ll_l=${ll_a[$ll_m]}
            if [[ $ll_l != $ll_ll ]]; then
                node_set $1 $ll_ll.$4.$5.a.$ll_m $ll_l
            fi
        done
    done
}

cd_branch_line() {
    # USAGE: cd_branch_line DB line $line $turn $side "${move[@]}"

    #local _db=$1
    eval "local -n bl_nl=$2"  # New line
    #local bl_cl=$3           # Current line ...
    #local bl_ct=$4
    #local bl_cs=$5
    #local bl_nm=$6 ...       # New move(s)
    local ii jj

    # Get moves for current line (up to current move)
    local -a bl_mvs
    cd_gather_moves $1 bl_mvs $3 1 w $4 $5

    # Add moves (sans last) to new line
    if ! cd_gen_line $1 $2 "${bl_mvs[@]:0:${#bl_mvs[@]}-1}"; then
        cd_del_line $1 $bl_nl
        return 1
    fi
    node_del $1 $bl_nl.m   # This is a derived line

    # Add first alt move
    if ! cd_add_moves $1 $bl_nl ii jj "$6"; then
        return 1
    fi

    # Set description
    node_get $1 $bl_nl.$ii.$jj.m jj
    node_get $1 $3.c ii
    part +1 ' ' "$ii" ii
    if [[ $5 == w ]]; then
        ii+=" ($4. $jj)"
    else
        ii+=" ($4... $jj)"
    fi
    node_set $1 $bl_nl.c "$ii"

    # Add remaining moves
    if [[ $# -gt 6 ]]; then
        if ! cd_add_moves $1 $bl_nl ii jj "${@:7}"; then
            return 1
        fi
    fi

    # Copy start point and rotation
    for ii in s r; do
        if node_get -q $1 $3.$ii jj; then
            node_set $1 $bl_nl.$ii "$jj"
        fi
    done

    # Copy alts for earlier moves to new line
    cd_copy_alts $1 $3 $bl_nl $4 $5

    # Sync alt moves between the two lines for current move
    cd_link_lines $1 $3 $bl_nl $4 $5
    return 0
}

#####

cd_mt_line() {
    # USAGE: cd_mt_line DB line
    #local mt_db=$1
    eval "local -n mt_l=$2"

    cd_next $1 _ $2
    node_set $1 $mt_l.c "Line #$mt_l"
    node_set $1 $mt_l.m main
}

cd_set_moves() {
    # USAGE: cd_set_moves DB $line $turn $side "$fen" "${moves[@]}"

    #local sm_db=$1
    #local sm_l=$2
    local sm_t=$3
    local sm_s=$4
    #local sm_fen=$5

    local -A sm_brd
    cm_set_board sm_brd "$5"

    cd_truncate_line $1 $2 $3 $4

    local sm_mv sm_m
    for sm_mv in "${@:6}"; do
        if [[ $sm_mv =~ ^[0-9]+\.$ ]]; then
            continue
        fi
        # Add engine moves
        if [[ $sm_mv =~ ^[a-h][1-8][a-h][1-8]$ ]]; then
            if cm_move_eng sm_brd $sm_mv sm_m; then
                node_set $1 $2.$sm_t.$sm_s.m "$sm_m"
                node_set $1 $2.$sm_t.$sm_s.f "${sm_brd[fen]}"
                cm_next -f $1 $2 sm_t sm_s
            else
                GBL[ERR]="Error adding move '$sm_mv': ${sm_brd[err]}"
                return 1
            fi
        elif cm_move sm_brd "$sm_mv"; then
            node_set $1 $2.$sm_t.$sm_s.m "${sm_brd[move]}"
            node_set $1 $2.$sm_t.$sm_s.f "${sm_brd[fen]}"
            cm_next -f $1 $2 sm_t sm_s
        else
            GBL[ERR]="Error adding move '$sm_mv': ${sm_brd[err]}"
            return 1
        fi
    done
    return 0
}

cd_add_moves() {
    # USAGE: cd_add_moves DB $line turn side "${moves[@]}"

    #local am_db=$1
    #local am_l=$2
    eval "local -n am_t=$3"
    eval "local -n am_s=$4"

    cm_last $1 $2 am_t am_s
    local am_fen
    node_get $1 $2.$am_t.$am_s.f am_fen
    cm_next -f $1 $2 am_t am_s
    if ! cd_set_moves $1 $2 $am_t $am_s "$am_fen" "${@:5}"; then
        return 1
    fi
    cd_fenify $1 $2
    return 0
}

cd_gen_line() {
    # USAGE: cd_gen_line DB line moves...

    #local gl_db=$1
    eval "local -n gl_l=$2"

    cd_mt_line $1 $2
    cd_set_moves $1 $gl_l 1 w '' "${@:3}"
}

cd_new_line() {
    # USAGE: cd_new_line DB line ["${move[@]}"]

    if [[ $# -le 2 ]]; then
        echo -e "\nCreating new line of study"
        local nl_mvs
        while [[ -z $nl_mvs ]]; do
            read -p "Enter initial move(s): " nl_mvs
        done
        cd_gen_line $1 $2 $nl_mvs
    else
        cd_gen_line "$@"
    fi
}

#####

cd_del_move() {
    # USAGE: cd_del_moves DB $line $turn $side
    #local dm_db=$1
    #local dm_l=$2
    #local dm_t=$3
    #local dm_s=$4

    local dm_m dm_a dm_l

    # Get move being deleted
    if node_get -q $1 $2.$3.$4.m dm_m; then
        # Delete alts on other lines for this move
        for dm_a in $(node_get -q $1 $2.$3.$4.a); do
            if node_get -q $1 $2.$3.$4.a.$dm_a dm_l; then
                node_del -q $1 $dm_l.$3.$4.a.$dm_m
            fi
        done
    fi

    # Delete move
    node_del -q $1 $2.$3.$4
    if node_exists $1 $2.$3 && node_is_null $1 $2.$3; then
        node_del -q $1 $2.$3
    fi
}

cd_truncate_line() {
    # USAGE: cd_truncate_line DB $line $turn $side
    #local tl_db=$1
    #local tl_l=$2
    #local tl_t=$3
    #local tl_s=$4

    local tl_t tl_ss
    cm_last $1 $2 tl_tt tl_ss
    while [[ $tl_tt -gt $3 || \
            ( $tl_tt -eq $3 && ( $tl_ss == b || $4 == w ) ) ]]
    do
        cd_del_move $1 $2 $tl_tt $tl_ss
        if ! cm_next -b $1 $2 tl_tt tl_ss; then
            break
        fi
    done
    #cd_orphan $1
}

cd_del_line() {
    # USAGE: cd_create_line DB $line
    #local dl_db=$1
    #local dl_l=$2

    # Delete all moves
    cd_truncate_line $1 $2 1 w

    # Delete line
    node_del -q $1 $2

    #cd_orphan $1
}

#####

cd_gather_moves() {
    # USAGE: cd_gather_moves DB moves $line [$turn $side [$turn $side]]
    #local gm_db=$1
    eval "local -n gm_mvs=$2"
    #local gm_l=$3
    local gm_fm_t=${4:-1}
    local gm_fm_s=${5:-w}
    local gm_to_t=${6:-999}
    local gm_to_s=${7:-b}

    local gm_mv
    gm_mvs=()
    while [[ $gm_fm_t -lt $gm_to_t || \
           ( $gm_fm_t -eq $gm_to_t && \
                ( $gm_fm_s == w || $gm_to_s == b ) ) ]]
    do
        if ! node_get -q $1 $3.$gm_fm_t.$gm_fm_s.m gm_mv; then
            break
        fi
        gm_mvs+=("$gm_mv")
        cm_next -f $1 $3 gm_fm_t gm_fm_s
    done
}

#####

cd_next() {
    # USAGE: cd_next DB $path result
    #local ni_db=$1
    #local ni_n=$2
    eval "local -n ni_x=$3"; ni_x=1
    while node_exists $1 $2.$ni_x; do (( ni_x++ )); done
}

#####

cd_orphan() {
    # USAGE: cd_orphan DB
    eval "local -n ol_db=$1"

    # Separate main and alternate lines
    local -A ol_mn ol_al
    local ol_ii
    for ol_ii in $(node_get $1); do
        if [[ -v "ol_db[$ol_ii.m]" ]]; then
            ol_mn[$(part +$ . $ol_ii)]=$ol_ii
        else
            ol_al[$(part +$ . $ol_ii)]=$ol_ii
        fi
    done

    while [[ ${#ol_al[@]} -gt 0 ]]; do
        # For all alt moves in main lines, and delete the alt line from 'ol_al'
        for ol_ii in "${!ol_db[@]}"; do
            if [[ $ol_ii =~ ^_\.([0-9]+)\.[0-9]+\.(b|w)\.a\..+$ ]]; then
                if [[ -n ${ol_mn[${BASH_REMATCH[1]}]} ]]; then
                    unset ol_al[${ol_db[$ol_ii]}]
                fi
            fi
        done
        # Mark one of the remaining alt lines as main
        for ol_ii in "${!ol_al[@]}"; do
            node_set $1 ${ol_al[$ol_ii]}.m main
            unset ol_al[$ol_ii]
        done
    done
}

#####

cd_cluster() {
    # USAGE: cd_cluster DB lines
    eval "local -n lc_db=$1"
    eval "local -n lc_lns=$2"

    local lc_ii lc_jj lc_l1 lc_l2 lc_c1 lc_c2

    # Find main lines
    local -A lc_mns
    for lc_l1 in $(node_get $1); do
        if [[ -v "lc_db[$lc_l1.m]" ]]; then
            part +$ . $lc_l1 lc_l1
            lc_mns[$lc_l1]=$lc_l1
        fi
    done

    # Create clusters of lines
    lc_lns=()
    for lc_ii in "${!lc_db[@]}"; do
        if [[ $lc_ii =~ ^_\.([0-9]+)\.[0-9]+\.(b|w)\.a\..+$ ]]; then
            lc_l1=${BASH_REMATCH[1]}
            lc_l2=${lc_db[$lc_ii]}
            if [[ -v "lc_lns[$lc_l1]" ]]; then
                if [[ -v "lc_lns[$lc_l2]" ]]; then
                    # Merge clusters
                    if [[ -v "lc_mns[${lc_lns[$lc_l1]}]" ]]; then
                        lc_c1=${lc_lns[$lc_l1]}
                        lc_c2=${lc_lns[$lc_l2]}
                    else
                        lc_c1=${lc_lns[$lc_l2]}
                        lc_c2=${lc_lns[$lc_l1]}
                    fi
                    for lc_jj in ${!lc_lns[@]}; do
                        if [[ ${lc_lns[$lc_jj]} -eq $lc_c2 ]]; then
                            lc_lns[$lc_jj]=$lc_c1
                        fi
                    done
                else
                    lc_lns[$lc_l1]=${lc_lns[$lc_l1]}
                fi
            elif [[ -v "lc_lns[$lc_l2]" ]]; then
                lc_lns[$lc_l1]=${lc_lns[$lc_l2]}
            elif [[ -v "lc_mns[$lc_l2]" ]]; then
                lc_lns[$lc_l1]=$lc_l2
                lc_lns[$lc_l2]=$lc_l2
            else
                lc_lns[$lc_l1]=$lc_l1
                lc_lns[$lc_l2]=$lc_l1
            fi
        fi
    done
}

cd_extract() {
    # USAGE: cd_extract DB1 DB2 $line
    eval "local -n ex_db1=$1"
    eval "local -n ex_db2=$2"
    #local ex_l=$3

    # Create clusters of lines
    local -A ex_lns
    cd_cluster $1 ex_lns

    # If all same cluster, abort
    local ex_c1=${ex_lns[$3]} ex_c2
    for ex_c2 in ${ex_lns[@]}; do
        if [[ $ex_c2 -ne $ex_c1 ]]; then
            break
        fi
    done
    if [[ $ex_c2 -eq $ex_c1 ]]; then
        GBL[ERR]='Cannot extract.  Only one cluster of lines.'
        return 1
    fi

    # Copy DB
    tree_copy $1 $2

    # Extract cluster for specified line
    local ex_l
    ex_c1=${ex_lns[$3]}
    for ex_l in ${!ex_lns[@]}; do
        if [[ ${ex_lns[$ex_l]} -eq $ex_c1 ]]; then
            cd_del_line $1 $ex_l   # Remove extracted line from old DB
        else
            cd_del_line $2 $ex_l   # Remove non-extracted line from new DB
        fi
    done
    return 0
}


<<'__NOTES__'

_.l
    line

_.l.c/m/s/r/t
    comment
    main
    start
    rotate
    timestamp

_.l.t.s
    turn
    side = w/b

_.l.t.s.m/c/a/e
    move
    comment
    alts
    engine

_.l.t.s.a.M
    move -> line

_.l.t.s.e.#.t.s.m/r/d/s
    rank
    depth
    score
    moves
_.l.t.s.e.#.t.s+.m

__NOTES__

# EOF
