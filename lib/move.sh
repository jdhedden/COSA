#!/usr/bin/bash

declare -A F2N=([a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8)
declare -a N2F=('' a b c d e f g h)
declare -A PIECE=([K]=King [Q]=Queen [R]=Rook [B]=Bishop [N]=Knight [P]=Pawn)
declare -A SIDE=([w]=White [b]=Black)

declare START_FEN='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'


cm_is_check () {
    # USAGE: cm_is_check BOARD [--other_side]

    local -n ic_brd=$1
    local ic_s
    if [[ $2 == '--other_side' ]]; then
        ic_s=$(echo ${ic_brd[side]} | tr bw wb)
    else
        ic_s=${ic_brd[side]}
    fi

    local ic_p
    local -A ic_att
    if [[ $ic_s == w ]]; then
        ic_p=K
        ic_att=([K]=k [QR]=qr [QB]=qb [N]=n [P]=p)
    else
        ic_p=k
        ic_att=([K]=K [QR]=QR [QB]=QB [N]=N [P]=P)
    fi
    local ic_kf=${ic_brd[$ic_p]:0:1}
    local ic_kr=${ic_brd[$ic_p]:1:1}
    local ic_f ic_r ic_x ic_y ic_fm

    local -a ic_ck

    # Illegal K next to K
    for ic_x in 1 0 -1; do
        ic_f=$(( ${F2N[$ic_kf]} + ic_x ))
        for ic_y in 1 0 -1; do
            ic_r=$(( ic_kr + ic_y ))
            ic_fm=${N2F[$ic_f]}$ic_r
            ic_p=${ic_brd[$ic_fm]}
            if [[ $ic_p == ${ic_att[K]} ]]; then
                ic_ck+=("$ic_p on $ic_fm")
            fi
        done
    done

    # Q/R attack
    for ic_x in 1 -1; do
        ic_f=$(( ${F2N[$ic_kf]} + ic_x ))
        while [[ $ic_f -ge 1 && $ic_f -le 8 ]]; do
            ic_fm=${N2F[$ic_f]}$ic_kr
            ic_p=${ic_brd[$ic_fm]}
            if [[ -n $ic_p ]]; then
                if [[ ${ic_att[QR]} =~ $ic_p ]]; then
                    ic_ck+=("$ic_p on $ic_fm")
                else
                    break
                fi
            fi
            ic_f=$(( ic_f + ic_x ))
        done
    done
    for ic_y in 1 -1; do
        ic_r=$(( ic_kr + ic_y ))
        while [[ $ic_r -ge 1 && $ic_r -le 8 ]]; do
            ic_fm=$ic_kf$ic_r
            ic_p=${ic_brd[$ic_fm]}
            if [[ -n $ic_p ]]; then
                if [[ ${ic_att[QR]} =~ $ic_p ]]; then
                    ic_ck+=("$ic_p on $ic_fm")
                else
                    break
                fi
            fi
            ic_r=$(( ic_r + ic_y ))
        done
    done

    # Q/B attack
    for ic_x in 1 -1; do
        for ic_y in 1 -1; do
            ic_f=$(( ${F2N[$ic_kf]} + ic_x ))
            ic_r=$(( ic_kr + ic_y ))
            while [[ $ic_f -ge 1 && $ic_f -le 8 && $ic_r -ge 1 && $ic_r -le 8 ]]; do
                ic_fm=${N2F[$ic_f]}$ic_r
                ic_p=${ic_brd[$ic_fm]}
                if [[ -n $ic_p ]]; then
                    if [[ ${ic_att[QB]} =~ $ic_p ]]; then
                        ic_ck+=("$ic_p on $ic_fm")
                    else
                        break
                    fi
                fi
                ic_f=$(( ic_f + ic_x ))
                ic_r=$(( ic_r + ic_y ))
            done
        done
    done

    # N attack
    for ic_x in 1 2; do
        ic_y=$(( 3 - ic_x ))
        for ic_r in $(( ic_kr + ic_y )) $(( ic_kr - ic_y )); do
            for ic_f in $(( ${F2N[$ic_kf]} + ic_x )) $(( ${F2N[$ic_kf]} - ic_x )); do
                ic_fm=${N2F[$ic_f]}$ic_r
                ic_p=${ic_brd[$ic_fm]}
                if [[ $ic_p == ${ic_att[N]} ]]; then
                    ic_ck+=("$ic_p on $ic_fm")
                fi
            done
        done
    done

    # P attack
    if [[ $ic_s == w ]]; then ic_r=$(( ic_kr + 1 )); else ic_r=$(( ic_kr - 1 )); fi
    for ic_x in 1 -1; do
        ic_f=$(( ${F2N[$ic_kf]} + ic_x ))
        ic_fm=${N2F[$ic_f]}$ic_r
        ic_p=${ic_brd[$ic_fm]}
        if [[ $ic_p == ${ic_att[P]} ]]; then
            ic_ck+=("$ic_p on $ic_fm")
        fi
    done

    # Results
    ic_brd[check]=
    for ic_p in "${ic_ck[@]}"; do
        if [[ -n ${ic_brd[check]} ]]; then
            ic_brd[check]+="; "
        fi
        ic_brd[check]+="$ic_p"
    done

    if [[ -z ${ic_brd[check]} ]]; then
        return 1  # Not in check
    fi
    return 0  # Check
}


cm_parse_move () {
    # USAGE: cm_parse_move MOVE $move

    # move=(
    #   [move]      Original move text
    #   [piece]     Piece being moved (KQBNRP)
    #   [file]      Originating file for pawn move
    #   [orig]      Originating square of the piece (not parsed here)
    #   [dest]      Destination square of the piece
    #   [xture]     x = piece capture
    #   [dis]       Disambiguation info
    #   [check]     + = check; # = checkmate
    #   [promote]   Pawn promotion piece
    #   [castle]    O-O or O-O-O
    #   [err]       Error message
    #   [anno]      Annotation marks (!, ?, etc.)
    # )

    local -n pm_mv=$1
    pm_mv=([move]=$2)

    # Support case-insensitive moves
    if [[ ${pm_mv[move]} =~ ^([kqnr])([a-h]?[1-8]?)(x?)([a-h][1-8])([+#]?)([?!]*)$ ]]; then
        cm_parse_move $1 ${2^}
        return $?
    fi

    # Piece move
    if [[ ${pm_mv[move]} =~ ^([KQBNR])([a-h]?[1-8]?)(x?)([a-h][1-8])([+#]?)([?!]*)$ ]]; then
        pm_mv[piece]=${BASH_REMATCH[1]}
        pm_mv[dis]=${BASH_REMATCH[2]}
        pm_mv[xture]=${BASH_REMATCH[3]}
        pm_mv[dest]=${BASH_REMATCH[4]}
        pm_mv[check]=${BASH_REMATCH[5]}
        pm_mv[anno]=${BASH_REMATCH[6]}

    # Pawn move
    elif [[ ${pm_mv[move]} =~ ^([a-h]?)(x?)([a-h][1-8])((=(.))?)([+#]?)([?!]*)$ ]]; then
        pm_mv[piece]=P
        pm_mv[file]=${BASH_REMATCH[1]}
        pm_mv[xture]=${BASH_REMATCH[2]}
        pm_mv[dest]=${BASH_REMATCH[3]}
        pm_mv[promote]=${BASH_REMATCH[6]}
        pm_mv[check]=${BASH_REMATCH[7]}
        pm_mv[anno]=${BASH_REMATCH[8]}

        if [[ -n ${pm_mv[xture]} ]]; then
            if [[ -z ${pm_mv[file]} ]]; then
                pm_mv[err]="Missing pawn's file: $2"
                return 1
            fi
            _x=$(( ${F2N[${pm_mv[file]}]} - ${F2N[${pm_mv[dest]:0:1}]} ))
            if [[ ${_x#-} -ne 1 ]]; then
                if [[ ${pm_mv[file]} == b ]]; then
                    if cm_parse_move $1 ${2^}; then  # b -> B
                        return 0
                    fi
                fi
                pm_mv[err]="Invalid move - files not adjacent: $2"
                return 1
            fi
        else
            if [[ -n ${pm_mv[file]} ]]; then
                if [[ ${pm_mv[file]} == b ]]; then
                    if cm_parse_move $1 ${2^}; then  # b -> B
                        return 0
                    fi
                fi
                pm_mv[err]="Invalid move syntax: $2"
                return 1
            fi
            pm_mv[file]=${pm_mv[dest]:0:1}
        fi

        if [[ 18 =~ ${pm_mv[dest]:1:1} ]]; then
            if [[ -z ${pm_mv[promote]} ]]; then
                pm_mv[err]="Missing pawn promotion piece: $2"
                return 1
            elif [[ ! QBNRqbnr =~ ${pm_mv[promote]} ]]; then
                pm_mv[err]="Invalid pawn promotion piece: $2"
                return 1
            elif [[ qbnr =~ ${pm_mv[promote]} ]]; then
                pm_mv[promote]=${pm_mv[promote]^}
                pm_mv[move]=${pm_mv[move]:0:-1}${pm_mv[promote]}
            fi
        else
            if [[ -n ${pm_mv[promote]} ]]; then
                pm_mv[err]="Invalid rank for pawn promotion: $2"
                return 1
            fi
        fi

    # Castling
    elif [[ ${pm_mv[move]} =~ ^[Oo0]-[Oo0](-[Oo0])?([+#]?)$ ]]; then
        pm_mv[castle]='O-O'
        if [[ -n ${BASH_REMATCH[1]} ]]; then
            pm_mv[castle]+='-O'
        fi
        pm_mv[check]=${BASH_REMATCH[2]}
        pm_mv[move]=${pm_mv[castle]}${pm_mv[check]}
        pm_mv[piece]=X

    else
        pm_mv[err]="Invalid move syntax: $2"
        return 1
    fi
    return 0
}


cm_move () {
    # USAGE: cm_move BOARD $move

    local -n mp_brd=$1
    local -A mp_tbrd  # Temp board

    local -A mp_mv
    if ! cm_parse_move mp_mv $2; then
        mp_brd[err]=${mp_mv[err]}
        return 1
    fi
    mp_brd[move]=${mp_mv[move]}

    local -A mp_pcs
    local mp_foe
    if [[ ${mp_brd[side]} == w ]]; then
        mp_pcs=([K]=K [Q]=Q [R]=R [B]=B [N]=N [P]=P)
        mp_foe='qrbnp'
    else
        mp_pcs=([K]=k [Q]=q [R]=r [B]=b [N]=n [P]=p)
        mp_foe='QRBNP'
    fi

    local mp_f mp_r mp_x mp_y mp_p mp_fm mp_fms mp_d

    # Currently in check?
    local mp_ck
    if cm_is_check $1; then
        mp_ck=${mp_brd[check]}
    fi

    if [[ KQBNRP =~ ${mp_mv[piece]} ]]; then
        # Possible disambiguations
        if [[ -n ${mp_mv[dis]} ]]; then
            case ${mp_mv[dis]} in
                [a-h][1-8]) mp_d=${mp_mv[dis]}    ;;
                [a-h])      mp_d="${mp_mv[dis]}." ;;
                [1-8])      mp_d=".${mp_mv[dis]}" ;;
            esac
            mp_d=$(echo ${mp_brd[${mp_pcs[${mp_mv[piece]}]}]} | grep -o $mp_d | xargs)
            if [[ -z $mp_d ]]; then
                mp_brd[err]="No ${PIECE[${mp_mv[piece]}],?} fits disambiguation '${mp_mv[dis]}'"
                return 1
            fi
        fi

        # General move validation
        if [[ -z ${mp_brd[${mp_pcs[${mp_mv[piece]}]}]} ]]; then
            mp_brd[err]="${SIDE[${mp_brd[side]}]} doesn't have any ${PIECE[${mp_mv[piece]}],?}s"
            return 1
        fi

        mp_p=${mp_brd[${mp_mv[dest]}]}
        if [[ -z $mp_p ]]; then
            if [[ -n ${mp_mv[xture]} ]]; then
                if [[ ${mp_mv[dest]} != ${mp_brd[enpass]} ]]; then
                    mp_brd[err]="Nothing to capture on ${mp_mv[dest]}"
                    return 1
                fi
            fi
        elif [[ ${mp_brd[${mp_mv[dest]}]} == ${mp_pcs[${mp_mv[piece]}]} ]]; then
            mp_brd[err]="${PIECE[${mp_mv[piece]}]} already on ${mp_mv[dest]}"
            return 1
        elif [[ -z ${mp_mv[xture]} ]]; then
            mp_brd[err]="Cannot move to ${mp_mv[dest]} (occupied by ${PIECE[${mp_p^?}],?})"
            return 1
        elif [[ ! $mp_foe =~ $mp_p ]]; then
            mp_brd[err]="Cannot capture ${PIECE[${mp_p^?}],?} on ${mp_mv[dest]}"
            return 1
        fi
    fi

    if [[ QRBNK =~ ${mp_mv[piece]} ]]; then
        # Find originating square
        if [[ QR =~ ${mp_mv[piece]} ]]; then
            mp_r=${mp_mv[dest]:1:1}
            for mp_x in 1 -1; do
                mp_f=$(( ${F2N[${mp_mv[dest]:0:1}]} + mp_x ))
                while [[ $mp_f -ge 1 && $mp_f -le 8 ]]; do
                    mp_fm=${N2F[$mp_f]}$mp_r
                    mp_p=${mp_brd[$mp_fm]}
                    if [[ -n $mp_p ]]; then
                        if [[ $mp_p == ${mp_pcs[${mp_mv[piece]}]} ]]; then
                            if [[ -z $mp_d || $mp_d =~ $mp_fm ]]; then
                                mp_fms+=" $mp_fm"
                            fi
                        fi
                        break
                    fi
                    mp_f=$(( mp_f + mp_x ))
                done
            done
            mp_f=${F2N[${mp_mv[dest]:0:1}]}
            for mp_y in 1 -1; do
                mp_r=$(( ${mp_mv[dest]:1:1} + mp_y ))
                while [[ $mp_r -ge 1 && $mp_r -le 8 ]]; do
                    mp_fm=${N2F[$mp_f]}$mp_r
                    mp_p=${mp_brd[$mp_fm]}
                    if [[ -n $mp_p ]]; then
                        if [[ $mp_p == ${mp_pcs[${mp_mv[piece]}]} ]]; then
                            if [[ -z $mp_d || $mp_d =~ $mp_fm ]]; then
                                mp_fms+=" $mp_fm"
                            fi
                        fi
                        break
                    fi
                    mp_r=$(( mp_r + mp_y ))
                done
            done
        fi

        if [[ QB =~ ${mp_mv[piece]} ]]; then
            for mp_x in 1 -1; do
                for mp_y in 1 -1; do
                    mp_f=$(( ${F2N[${mp_mv[dest]:0:1}]} + mp_x ))
                    mp_r=$(( ${mp_mv[dest]:1:1} + mp_y ))
                    while [[ $mp_f -ge 1 && $mp_f -le 8 && $mp_r -ge 1 && $mp_r -le 8 ]]; do
                        mp_fm=${N2F[$mp_f]}$mp_r
                        mp_p=${mp_brd[$mp_fm]}
                        if [[ -n $mp_p ]]; then
                            if [[ $mp_p == ${mp_pcs[${mp_mv[piece]}]} ]]; then
                                if [[ -z $mp_d || $mp_d =~ $mp_fm ]]; then
                                    mp_fms+=" $mp_fm"
                                fi
                            fi
                            break
                        fi
                        mp_f=$(( mp_f + mp_x ))
                        mp_r=$(( mp_r + mp_y ))
                    done
                done
            done

        elif [[ N == ${mp_mv[piece]} ]]; then
            for mp_x in 1 2; do
                mp_y=$(( 3 - mp_x ))
                for mp_r in $(( ${mp_mv[dest]:1:1} + mp_y )) $(( ${mp_mv[dest]:1:1} - mp_y )); do
                    for mp_f in $(( ${F2N[${mp_mv[dest]:0:1}]} + mp_x )) $(( ${F2N[${mp_mv[dest]:0:1}]} - mp_x )); do
                        mp_fm=${N2F[$mp_f]}$mp_r
                        mp_p=${mp_brd[$mp_fm]}
                        if [[ $mp_p == ${mp_pcs[N]} ]]; then
                            if [[ -z $mp_d || $mp_d =~ $mp_fm ]]; then
                                mp_fms+=" $mp_fm"
                            fi
                        fi
                    done
                done
            done

        elif [[ K == ${mp_mv[piece]} ]]; then
            for mp_x in 1 0 -1; do
                mp_f=$(( ${F2N[${mp_mv[dest]:0:1}]} + mp_x ))
                for mp_y in 1 0 -1; do
                    mp_r=$(( ${mp_mv[dest]:1:1} + mp_y ))
                    mp_fm=${N2F[$mp_f]}$mp_r
                    mp_p=${mp_brd[$mp_fm]}
                    if [[ $mp_p == ${mp_pcs[K]} ]]; then
                        if [[ -z $mp_d || $mp_d =~ $mp_fm ]]; then
                            mp_fms+=" $mp_fm"
                        fi
                        break 2
                    fi
                done
            done
        fi

        if [[ -z $mp_fms ]]; then
            if [[ -z $mp_d ]]; then
                mp_brd[err]="${PIECE[${mp_mv[piece]}]} cannot reach ${mp_mv[dest]}"
            elif [[ ${#mp_d} -eq 2 ]]; then
                mp_brd[err]="${PIECE[${mp_mv[piece]}]} on $mp_d cannot reach ${mp_mv[dest]}"
            else
                mp_brd[err]="${PIECE[${mp_mv[piece]}]}s on $mp_d cannot reach ${mp_mv[dest]}"
            fi
            return 1
        fi

        # Check for pinned piece
        mp_fm=
        for mp_x in $mp_fms; do
            copy_hash $1 mp_tbrd
            # Remove captured piece if applicable
            if [[ -n ${mp_mv[xture]} ]]; then
                mp_p=${mp_tbrd[${mp_mv[dest]}]}
                mp_tbrd[$mp_p]=${mp_tbrd[$mp_p]/${mp_mv[dest]}/}
            fi
            # Move piece
            mp_tbrd[${mp_pcs[${mp_mv[piece]}]}]=${mp_tbrd[${mp_pcs[${mp_mv[piece]}]}]/$mp_x/${mp_mv[dest]}}
            mp_tbrd[${mp_mv[dest]}]=${mp_pcs[${mp_mv[piece]}]}
            mp_tbrd[$mp_x]=''
            # Check for pin
            if ! cm_is_check mp_tbrd; then
                mp_fm+=" $mp_x"
            elif [[ ${mp_mv[piece]} == K ]]; then
                mp_brd[err]="Cannot move into check (${mp_tbrd[check]})"
                return 1
            fi
        done
        if [[ -z $mp_fm ]]; then
            if [[ -z $mp_ck ]]; then
                mp_brd[err]="${PIECE[${mp_mv[piece]}]} is pinned"
            else
                mp_brd[err]="King exposed to or remains in check"
            fi
            if [[ ${#mp_fms} -eq 3 ]]; then
                mp_brd[err]+=" (${mp_tbrd[check]})"
            fi
            return 1
        elif [[ ${#mp_fm} -eq 3 ]]; then
            mp_mv[orig]=${mp_fm:1}
        else
            if [[ -z $mp_d ]]; then
                mp_brd[err]="Need disambiguation: ${PIECE[${mp_mv[piece]}]}s on$mp_fm"
            else
                mp_brd[err]="Invalid disambiguation ('${mp_mv[dis]}'): ${PIECE[${mp_mv[piece]}]}s on$mp_fm"
            fi
            return 1
        fi

        # Remove captured piece if applicable
        copy_hash $1 mp_tbrd
        if [[ -n ${mp_mv[xture]} ]]; then
            mp_p=${mp_brd[${mp_mv[dest]}]}
            mp_brd[$mp_p]=${mp_brd[$mp_p]/${mp_mv[dest]}/}
        fi

        # Move piece
        mp_brd[${mp_pcs[${mp_mv[piece]}]}]=${mp_brd[${mp_pcs[${mp_mv[piece]}]}]/${mp_mv[orig]}/${mp_mv[dest]}}
        mp_brd[${mp_mv[dest]}]=${mp_pcs[${mp_mv[piece]}]}
        mp_brd[${mp_mv[orig]}]=''

        mp_brd[enpass]='-'

    elif [[ P == ${mp_mv[piece]} ]]; then
        mp_fms=$(echo ${mp_brd[${mp_pcs[P]}]} | grep -o ${mp_mv[file]}. | xargs)
        if [[ -z $mp_fms ]]; then
            if [[ ${mp_mv[file]} == 'b' && ${mp_mv[dest]:0:1} =~ [ac] && -n ${mp_mv[xture]} ]]; then
                if cm_move $1 ${2^}; then   # b -> B
                    return 0
                fi
            fi
            mp_brd[err]="No pawn on '${mp_mv[file]}' file"
            return 1
        fi

        if [[ ${mp_brd[side]} == w ]]; then mp_y=1; else mp_y=-1; fi
        for mp_x in $mp_fms; do
            if [[ $(( ${mp_x:1:1} + mp_y )) -eq ${mp_mv[dest]:1:1} ]]; then
                mp_mv[orig]=$mp_x
                break
            fi
        done

        if [[ -z ${mp_mv[orig]} ]]; then
            if [[ -n ${mp_mv[xture]} ]]; then
                if [[ ${mp_mv[file]} == 'b' && ${mp_mv[dest]:0:1} =~ [ac] ]]; then
                    if cm_move $1 ${2^}; then   # b -> B
                        return 0
                    fi
                fi
                mp_brd[err]="No pawn on '${mp_mv[file]}' file can capture to ${mp_mv[dest]}"
                return 1
            fi
            # Move 2 spaces?
            for mp_x in $mp_fms; do
                if [[ $(( ${mp_x:1:1} + mp_y*2 )) -eq ${mp_mv[dest]:1:1} ]]; then
                    mp_mv[orig]=$mp_x
                    break
                fi
            done
            if [[ -z ${mp_mv[orig]} ]]; then
                mp_brd[err]="No pawn on '${mp_mv[file]}' file can move to ${mp_mv[dest]}"
                return 1
            fi
            # On initial rank?
            if [[ ( ${mp_brd[side]} == w && ${mp_mv[orig]:1:1} -ne 2 ) || \
                  ( ${mp_brd[side]} == b && ${mp_mv[orig]:1:1} -ne 7 ) ]]
            then
                mp_brd[err]="Pawn cannot move from ${mp_mv[orig]} to ${mp_mv[dest]}"
                return 1
            fi
            # Check if blocked
            mp_fm="${mp_mv[orig]:0:1}$(( ${mp_mv[orig]:1:1} + mp_y ))"
            mp_p=${mp_brd[$mp_fm]}
            if [[ -n $mp_p ]]; then
                mp_brd[err]="Pawn cannot move from ${mp_mv[orig]} to ${mp_mv[dest]} (${PIECE[${mp_p^?}],?} on $mp_fms)"
                return 1
            fi
            mp_brd[_enpass]=$mp_fm   # Delay setting until after possible capture
        else
            mp_brd[_enpass]='-'
        fi

        # Remove captured piece if applicable
        copy_hash $1 mp_tbrd
        if [[ ${mp_mv[dest]} == ${mp_brd[enpass]} ]]; then
            # En passant capture
            mp_y="${mp_mv[dest]:0:1}${mp_mv[orig]:1:1}"
            mp_p=${mp_brd[$mp_y]}
            unset "mp_brd[$mp_y]"
            mp_brd[$mp_p]=${mp_brd[$mp_p]/$mp_y/}
        elif [[ -n ${mp_mv[xture]} ]]; then
            mp_p=${mp_brd[${mp_mv[dest]}]}
            mp_brd[$mp_p]=${mp_brd[$mp_p]/${mp_mv[dest]}/}
        fi

        # Set en passant status
        mp_brd[enpass]=${mp_brd[_enpass]}
        unset 'mp_brd[_enpass]'

        # Move pawn
        mp_brd[${mp_pcs[P]}]=${mp_brd[${mp_pcs[P]}]/${mp_mv[orig]}/${mp_mv[dest]}}
        mp_brd[${mp_mv[dest]}]=${mp_pcs[P]}
        mp_brd[${mp_mv[orig]}]=''

        # Check?
        if cm_is_check $1; then
            if [[ -z $mp_ck ]]; then
                mp_x="Pawn is pinned (${mp_brd[check]})"
            else
                mp_x="King exposed to or remains in check (${mp_brd[check]})"
            fi
            copy_hash mp_tbrd $1
            mp_brd[err]=$mp_x
            return 1
        fi

        # Pawn promotion
        if [[ -n ${mp_mv[promote]} ]]; then
            mp_brd[${mp_mv[dest]}]=${mp_pcs[${mp_mv[promote]}]}
            mp_brd[${mp_pcs[P]}]=${mp_brd[${mp_pcs[P]}]/${mp_mv[dest]}/}
            mp_brd[${mp_pcs[${mp_mv[promote]}]}]+=${mp_mv[dest]}
        fi

    elif [[ -n ${mp_mv[castle]} ]]; then
        if [[ -n $mp_ck ]]; then
            mp_brd[err]="Cannot castle while in check ($mp_ck)"
            return 1
        fi

        if [[ ${mp_brd[side]} == w ]]; then mp_r=1; else mp_r=8; fi

        local -A mp_xs=([O-O]=kingside [O-O-O]=queenside)

        local -A mp_sc=([wO-O]=K [bO-O]=k [wO-O-O]=Q [bO-O-O]=q)
        if [[ ! ${mp_brd[castle]} =~ ${mp_sc[${mp_brd[side]}${mp_mv[castle]}]} ]]; then
            mp_brd[err]="Not eligible to castle ${mp_xs[${mp_mv[castle]}]}"
            return 1
        fi

        local -A mp_blk=([O-O]='f g' [O-O-O]='b c d')
        for mp_f in ${mp_blk[${mp_mv[castle]}]}; do
            if [[ -n ${mp_brd[$mp_f$mp_r]} ]]; then
                mp_brd[err]="${mp_xs[${mp_mv[castle]}]} castling blocked (${PIECE[${mp_brd[$mp_f$mp_r]^?}],?} on ${N2F[$mp_f]}$mp_r)"
                return 1
            fi
        done

        local -A mp_mvs=([KO-O]='e f g' [KO-O-O]='e d c' [RO-O]='h f' [RO-O-O]='a d')

        copy_hash $1 mp_tbrd

        # Move king
        local -a mp_ff=(${mp_mvs[K${mp_mv[castle]}]})
        mp_brd[${mp_ff[1]}$mp_r]=${mp_brd[${mp_ff[0]}$mp_r]}
        mp_brd[${mp_ff[0]}$mp_r]=''
        mp_brd[${mp_pcs[K]}]="${mp_ff[1]}$mp_r"
        if cm_is_check $1; then
            mp_x="Cannot castle ${mp_xs[${mp_mv[castle]}]} through check (${mp_brd[check]})"
            copy_hash mp_tbrd $1
            mp_brd[err]=$mp_x
            return 1
        fi
        mp_brd[${mp_ff[2]}$mp_r]=${mp_brd[${mp_ff[1]}$mp_r]}
        mp_brd[${mp_ff[1]}$mp_r]=''
        mp_brd[${mp_pcs[K]}]="${mp_ff[2]}$mp_r"

        # Move rook
        mp_ff=(${mp_mvs[R${mp_mv[castle]}]})
        mp_brd[${mp_ff[1]}$mp_r]=${mp_brd[${mp_ff[0]}$mp_r]}
        mp_brd[${mp_ff[0]}$mp_r]=''
        mp_brd[${mp_pcs[R]}]=${mp_brd[${mp_pcs[R]}]/${mp_ff[0]}$mp_r/${mp_ff[1]}$mp_r}

        if cm_is_check $1; then
            mp_x="Cannot castle ${mp_xs[${mp_mv[castle]}]} into check (${mp_brd[check]})"
            copy_hash mp_tbrd $1
            mp_brd[err]=$mp_x
            return 1
        fi

        mp_brd[enpass]='-'

    else
        mp_brd[err]="Invalid move"
        return 1
    fi

    # Validate check
    # NOTE: Does not test for checkmate
    if cm_is_check $1 --other_side; then
        if [[ -z ${mp_mv[check]} ]]; then
            copy_hash mp_tbrd $1
            mp_brd[err]="Missing check/mate (+/#) symbol"
            return 1
        fi
    else
        if [[ -n ${mp_mv[check]} ]]; then
            copy_hash mp_tbrd $1
            mp_brd[err]="Invalid check/mate (+/#) symbol"
            return 1
        fi
    fi

    # Update FEN - board
    mp_brd[board]=''
    local mp_mt=''
    for mp_r in 8 7 6 5 4 3 2 1; do
        for mp_f in a b c d e f g h; do
            if [[ -z ${mp_brd[${mp_f}$mp_r]} ]]; then
                if [[ -z $mp_mt ]]; then
                    mp_mt=0
                fi
                (( mp_mt++ ))
            else
                if [[ -n $mp_mt ]]; then
                    mp_brd[board]+=$mp_mt
                    mp_mt=''
                fi
                mp_brd[board]+=${mp_brd[${mp_f}$mp_r]}
            fi
        done
        if [[ -n $mp_mt ]]; then
            mp_brd[board]+=$mp_mt
            mp_mt=''
        fi
        mp_brd[board]+=/
    done
    mp_brd[board]=${mp_brd[board]:0:-1}

    # Update castling status
    if [[ ${mp_brd[castle]} != '-' ]]; then
        if [[ ${mp_brd[side]} == w ]]; then
            if [[ ${mp_brd[castle]} =~ K ]]; then
                if [[ ${mp_brd[e1]} != K || ${mp_brd[h1]} != R ]]; then
                    mp_brd[castle]=${mp_brd[castle]/K/}
                fi
            fi
            if [[ ${mp_brd[castle]} =~ Q ]]; then
                if [[ ${mp_brd[e1]} != K || ${mp_brd[a1]} != R ]]; then
                    mp_brd[castle]=${mp_brd[castle]/Q/}
                fi
            fi
        else
            if [[ ${mp_brd[castle]} =~ k ]]; then
                if [[ ${mp_brd[e8]} != k || ${mp_brd[h8]} != r ]]; then
                    mp_brd[castle]=${mp_brd[castle]/k/}
                fi
            fi
            if [[ ${mp_brd[castle]} =~ q ]]; then
                if [[ ${mp_brd[e8]} != k || ${mp_brd[a8]} != r ]]; then
                    mp_brd[castle]=${mp_brd[castle]/q/}
                fi
            fi
        fi
        if [[ -z ${mp_brd[castle]} ]]; then mp_brd[castle]='-'; fi
    fi

    # Update turn
    if [[ ${mp_brd[side]} == w ]]; then
        mp_brd[side]=b
    else
        (( mp_brd[turn]++ ))
        mp_brd[side]=w
    fi
    if [[ ${mp_mv[xture]} || ${mp_mv[piece]} == P ]]; then
        mp_brd[half]=0
    else
        (( mp_brd[half]++ ))
    fi

    # Update fen
    printf -v mp_brd[fen] '%s %s %s %s %s %s' ${mp_brd[board]} ${mp_brd[side]} ${mp_brd[castle]} ${mp_brd[enpass]} ${mp_brd[half]} ${mp_brd[turn]}
    return 0
}


cm_move_eng () {
    # USAGE: cm_move_eng BOARD $move result

    local -n me_brd=$1
    local me_in=$2 me_mv
    local -n me_alg=$3

    local me_fm=${me_in:0:2}
    local me_to=${me_in:2:2}

    local me_p=${me_brd[$me_fm]^}
    if [[ -z $me_p ]]; then
        me_brd[err]="No piece on $me_fm"
    fi

    local me_x=false   # capture
    if [[ -n ${me_brd[$me_to]} ]]; then
        me_x=true
    fi

    # Pawn move
    if [[ $me_p == P ]]; then
        # En passant
        if [[ $me_to == ${me_brd[enpass]} ]]; then
            me_x=true
        fi
        # Pawn move
        if $me_x; then
            me_mv=${me_fm:0:1}x$me_to
        else
            me_mv=$me_to
        fi
        # Pawn promotion
        if [[ -n ${me_in:4} ]]; then
            me_p=${me_in:4}
            me_mv+="=${me_p^}"
        fi
        # Check move
        if cm_move $1 $me_mv; then
            me_alg=$me_mv
            return 0

        elif [[ ${me_brd[err]} =~ ^Missing\ check ]]; then
            me_mv+='+'
            if cm_move $1 $me_mv; then
                me_alg=$me_mv
                return 0
            fi
        fi
        return 1
    fi

    # Castling
    if [[ $me_p == K ]]; then
        if [[ $me_in == e1g1 || $me_in == e8g8 ]]; then
            me_mv=O-O
        elif [[ $me_in == e1c1 || $me_in == e8c8 ]]; then
            me_mv=O-O-O
        fi
        if [[ -n $me_mv ]]; then
            if cm_move $1 $me_mv; then
                me_alg=$me_mv
                return 0

            elif [[ ${me_brd[err]} =~ ^Missing\ check ]]; then
                me_mv+='+'
                if cm_move $1 $me_mv; then
                    me_alg=$me_mv
                    return 0
                fi
            fi
            return 1
        fi
    fi

    # All other piece moves
    for ambig in '' ${me_fm:0:1} ${me_fm:1:1} $me_fm; do
        if $me_x; then
            me_mv=$me_p${ambig}x$me_to
        else
            me_mv=$me_p$ambig$me_to
        fi
        if cm_move $1 $me_mv; then
            me_alg=$me_mv
            unset 'me_brd[err]'
            return 0

        elif [[ ${me_brd[err]} =~ ^Missing\ check ]]; then
            me_mv+='+'
            if cm_move $1 $me_mv; then
                me_alg=$me_mv
                return 0
            fi
        fi
    done
    return 1
}


cm_next () {
    # USAGE: cm_next [-f] [-b] DB $line turn side

    local nm_fwd=true   # forward
    local nm_frc=false  # force
    case $1 in
        -f) nm_frc=true
            shift
            ;;
        -b) nm_fwd=false
            shift
            ;;
    esac

    #local nm_db=$1
    #local nm_l=$2
    local -n nm_t=$3
    local -n nm_s=$4

    if $nm_fwd; then
        local nm_tt=$nm_t nm_ss=$nm_s
        if [[ $nm_ss == w ]]; then
            nm_ss=b
        else
            (( nm_tt++ ))
            nm_ss=w
        fi
        if $nm_frc || node_exists $1 $2.$nm_tt.$nm_ss.m; then
            nm_t=$nm_tt; nm_s=$nm_ss
        else
            return 1
        fi
    else
        if [[ $nm_s == b ]]; then
            nm_s=w
        elif [[ $nm_t -eq 1 ]]; then
            #e_err "Nothing before white's first move"
            return 1
        else
            (( nm_t-- ))
            nm_s=b
        fi
    fi
    return 0
}


cm_is_last () {
    # USAGE: cm_is_last DB $line $turn $side

    #local il_db=$1
    #local il_l=$2
    local il_t=$3
    local il_s=$4

    if cm_next $1 $2 il_t il_s; then return 1; else return 0; fi
}


cm_last () {
    # USAGE: cm_last DB $line turn side

    #local lm_db=$1
    #local lm_l=$2
    local -n lm_t=$3
    local -n lm_s=$4

    local -a lm_turns
    node_get $1 $2 lm_turns
    if [[ ${#lm_turns[@]} -gt 5 ]]; then
        lm_t=$(( ${#lm_turns[@]} - 5 ))
    else
        lm_t=1
    fi

    lm_s=w

    while cm_next $1 $2 $3 $4; do : ; done
}


cm_set_board () {
    # USAGE: cm_set_board BOARD ["$fen"]
    local -n sb_brd=$1
    local -a sb_fen=(${2:-$START_FEN})

    sb_brd= ()
    sb_brd[fen]="${2:-$START_FEN}"
    sb_brd[board]=${sb_fen[0]}
    sb_brd[side]=${sb_fen[1]}
    sb_brd[castle]=${sb_fen[2]}
    sb_brd[enpass]=${sb_fen[3]}
    sb_brd[half]=${sb_fen[4]}
    sb_brd[turn]=${sb_fen[5]}

    local ii sb_r=8 sb_f=1
    for ii in $(echo ${sb_brd[board]} | grep -o .); do
        case $ii in
            /)
                (( sb_r-- ))
                sb_f=1
                ;;
            [1-8])
                sb_f=$(( sb_f + ii ))
                ;;
            *)
                sb_brd[${N2F[$sb_f]}$sb_r]=$ii
                sb_brd[$ii]+=${N2F[$sb_f]}$sb_r
                (( sb_f++ ))
                ;;
        esac
    done
}


cm_dump_move () {
    # USAGE: cm_dump_move move
    local -n dm_mv=$1

    echo
    local key
    for key in "${!dm_mv[@]}"; do
        echo "move[$key] = ${dm_mv[$key]}"
    done
    echo
}

cm_dump_board () {
    # USAGE: cm_dump_move board
    local -n db_brd=$1

    echo
    local key
    for key in "${!db_brd[@]}"; do
        echo "board[$key] = ${db_brd[$key]}"
    done
    echo
}


<<'__NOTES__'

nbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
1. e4
rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1
1... c5
rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2
2. Nf3
rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2

__NOTES__

# EOF
