#!/bin/bash

# Chess Opening Study Aid

# Usage:  cosa.sh [--debug] [db_file [-s $line.$turn.$side] [-w]]

export COSA=$(realpath $(dirname $0)/..)
. $COSA/lib/utils
UTIL[LIB]=$(realpath ${UTIL[DIR]}/../lib)
. ${UTIL[LIB]}/cfg.sh


declare -A GBL=(
    [DB_FILE]=
    [START]=
    [SAVE_DB]=true
    [ERR]=
)


commands() {
    cat <<__HELP__
${AES[unl]}Commands${AES[rst]}
<CR>                Next move
-                   Previous move
# [b]               Jump to move
$                   Jump to last move
_move_              Go to line for alt. move
!                   Go to starting position

line                Select a line of study
--                  Return to previous line (stacked)
!!|main             Go to main line

rot                 Rotate the board
rot -l              Change board rotation for line

cmt "..."           Add comment to current move
cmt -d              Delete comment for current move
cmt -l "..."        Change description for line

add _move_ ...      Add move(s) to end of line
del                 Delete from current move to end
del -l              Delete current line of study

alt _move_ ...      Create new line with alt. move(s)

new [_move_ ...]    Create new line of study
set main            Set to a main line of study
set start [# [b]]   Set starting move for line

extract             Extract cluster for current line to new DB

save                Write database to disk

list                List moves in line
fen                 Show the FEN for the current move

param               Set engine parameters
eng                 Run analysis engine

win                 Open currently line in a new window

DEBUG [true|false]  Turn on/set debug mode
DEFEN               Purge FENs from database

^D                  Exit (saves database)
ABORT               Exit without saving database

__HELP__
}


main() {
    local -A DB DB2 board
    local -a args hist ary
    local line turn=1 side=w
    local cur_line cur_turn cur_side
    local rotate=false
    local move fen msg
    local tmp

    local save_db=false
    tmp=${GBL[DB_FILE]}
    if ! cd_load DB tmp save_db; then
        exit 1
    fi
    GBL[DB_FILE]=$tmp

    if [[ -n ${GBL[START]} ]]; then
        ary=(${GBL[START]//./ })
        line=${ary[0]}
        turn=${ary[1]:-1}
        side=${ary[2]:-w}
    else
        if ! cd_choose_line DB line turn side; then
            echo 'Database is empty'
            cd_new_line DB line
            turn=1; side=w
            save_db=true
        fi
    fi
    if cd_fenify DB $line; then
        save_db=true
    fi

    cv_moves_and_board DB $line $turn $side $rotate
    echo

    while read -p "[$turn.$side] ? "; do
        args=($REPLY)
        case ${args[0]} in
            '')     # Next move
                cm_next DB $line turn side
                ;;
            -)      # Previous move
                cm_next -b DB $line turn side
                ;;
            --)     # Jump back in history
                tmp=$(( ${#hist[@]} - 1 ))
                if [[ $tmp -lt 0 ]]; then
                    msg='History stack is empty'
                else
                    ary=(${hist[$tmp]//./ })
                    line=${ary[0]}
                    turn=${ary[1]}
                    side=${ary[2]}
                    unset hist[$tmp]
                fi
                ;;
            [1-9]*) # Go to turn number
                if [[ ${args[0]} =~ ^([0-9]+)(\.?([bw]))? ]]; then
                    turn=${BASH_REMATCH[1]}
                    if [[ -z ${BASH_REMATCH[3]} ]]; then
                        side=${args[1]:-w}
                    else
                        side=${BASH_REMATCH[3]}
                    fi
                    if ! node_exists DB $line.$turn.$side.m; then
                        msg="No such move: ${args[@]}"
                        turn=1 side=w
                    fi
                else
                    msg="No such move: ${args[@]}"
                fi
                ;;
            $)      # Go to last move
                cm_last DB $line turn side
                ;;
            !)      # Go to starting move
                if node_get -q DB $line.s tmp; then
                    part +1 . $tmp turn
                    part +$ . $tmp side
                else
                    turn=1; side=w
                fi
                ;;
            !!|main) # Go to main line
                hist+=($line.$turn.$side)
                cd_main DB line turn side
                ;;
            line)   # Select a line of study
                hist+=($line.$turn.$side)
                cd_choose_line DB line turn side
                tmp=$(( ${#hist[@]} - 1 ))
                ary=(${hist[$tmp]//./ })
                if [[ $line == ${ary[0]} ]]; then
                    turn=${ary[1]}
                    side=${ary[2]}
                    unset hist[$tmp]
                    msg='No other lines in database'
                else
                    rotate=false
                fi
                ;;
            rot)    # Toggle rotate board; -l = toggle rotate for line
                if [[ -z ${args[1]} ]]; then
                    if $rotate; then rotate=false; else rotate=true; fi
                else
                    if node_del DB $line.r; then
                        msg='Line set to default rotation'
                    else
                        node_set DB $line.r '-r'
                        msg="Line set to rotation for black"
                    fi
                    save_db=true
                    rotate=false
                fi
                ;;
            add)    # Add move(s)
                cd_add_moves DB $line turn side "${args[@]:1}"
                save_db=true
                cm_last DB $line turn side
                e_debug "@ $line $turn $side"
                ;;
            alt)    # Add alternate move / create new line
                if node_exists DB $line.$turn.$side.a.${args[1]}; then
                    msg="Alternate move ${args[1]} already exists"
                else
                    hist+=($line.$turn.$side)
                    if cd_branch_line DB line $line $turn $side "${args[@]:1}"; then
                        save_db=true
                        cm_last DB $line turn side
                    else
                        tmp=$(( ${#hist[@]} - 1 ))
                        part +1 . ${hist[$tmp]} line
                        unset hist[$tmp]
                    fi
                fi
                ;;
            new)    # Create new line of study
                hist+=($line.$turn.$side)
                cd_new_line DB line "${args[@]:1}"
                if cd_fenify DB $line; then
                    save_db=true
                fi
                turn=1; side=w
                ;;
            set)
                if [[ ${args[1]} == main ]]; then
                    # Set line as main
                    node_set DB $line.m 1
                    save_db=true
                    msg='Set as a main line of study'
                elif [[ ${args[1]} == start ]]; then
                    # Set starting point
                    if [[ -z ${args[2]} ]]; then
                        node_set DB $line.s "$turn.$side"
                    elif [[ ${args[2]} =~ ^([0-9]+)(\.?([bw]))? ]]; then
                        turn=${BASH_REMATCH[1]}
                        if [[ -z ${BASH_REMATCH[3]} ]]; then
                            side=${args[3]:-w}
                        else
                            side=${BASH_REMATCH[3]}
                        fi
                        if node_exists DB $line.$turn.$side.m; then
                            node_set DB $line.s "$turn.$side"
                            save_db=true
                            msg="Starting point set to $turn.$side"
                        else
                            msg="No such move: ${args[@]:2}"
                        fi
                    else
                        msg="No such move: ${args[@]:2}"
                    fi
                else
                    msg="Unrecognized command: ${args[@]}"
                    args[0]='?'
                fi
                ;;
            del)    # Delete lines and moves
                if [[ ${args[1]} == '-l' || ( $turn -eq 1 && $side == w ) ]]; then
                    ask_confirm "Are you sure you want to delete this\nline of study?"
                    if is_confirmed; then
                        cd_del_line DB $line
                        cd_orphan DB
                        save_db=true
                        if ! cd_choose_line DB line turn side; then
                            echo 'Database is empty'
                            cd_new_line DB line
                            turn=1; side=w
                        fi
                        rotate=false
                    fi
                else   # Delete from current move onward
                    ask_confirm "Are you sure you want to delete move(s)\nfrom here to the end?"
                    if is_confirmed; then
                        cd_truncate_line DB $line $turn $side
                        cm_next -b DB $line turn side
                        cd_orphan DB
                        save_db=true
                    fi
                fi
                ;;
            cmt)    # Comments
                case ${args[1]} in
                    -l)  # Change line's description
                        node_set DB $line.c "${args[*]:2}"
                        ;;
                    -d)  # Delete move's comment
                        node_del -q DB $line.$turn.$side.c
                        ;;
                    *)   # Add comment to move
                        node_set DB $line.$turn.$side.c "${args[*]:1}"
                        ;;
                esac
                save_db=true
                ;;
            extract)  # Extract cluster of lines to new DB
                if cd_extract DB DB2 $line; then
                    save_db=true
                    tmp=
                    while [[ -z $tmp ]]; do
                        read -p 'Name for extracted DB: '
                        tmp=$REPLY
                        if [[ -n $tmp ]]; then
                            tmp=${UTIL[DAT]}/$tmp.dat
                            if [[ -f $tmp ]]; then
                                echo "DB called '$REPLY' already exists: $tmp"
                                tmp=
                            fi
                        fi
                    done
                    cd_save DB2 "$tmp"
                    unset DB2
                    msg="New DB saved to $tmp"
                    cv_window $tmp $line.$turn.$side
                    cd_choose_line DB line turn side
                fi
                ;;
            save)   # Write out DB
                if ! ${GBL[SAVE_DB]}; then
                    e_warn 'Database file is currently opened in another window'
                    ask_confirm "Save '$(basename -s .dat ${GBL[DB_FILE]})' anyway?"
                    if is_confirmed; then
                        GBL[SAVE_DB]=true
                    fi
                fi
                if ${GBL[SAVE_DB]}; then
                    cd_save DB ${GBL[DB_FILE]}
                    save_db=false
                    msg="Database '$(basename -s .dat ${GBL[DB_FILE]})' saved to disk"
                fi
                ;;
            list)   # List move in line
                cd_gather_moves DB ary $line
                msg="${ary[*]}"
                ;;
            fen)
                node_get DB $line.$turn.$side.f msg
                ;;
            par*)  # Set engine parameters
                ce_params
                msg="Engine parameters:
  Depth: ${ENG[depth]}
  Lines: ${ENG[/MultiPV]}
  Threads: ${ENG[/Threads]}
  Hash: ${ENG[/Hash]}
  Contempt: ${ENG[/Contempt]}"
                ;;
            eng)    # Run engine
                ce_engine DB $line $turn $side
                ;;
            win)    # Open new window
                # Line from alternate move, if any (otherwise current line)
                cur_line=$line
                if ! node_get -q DB $line.$turn.$side.a.${args[1]} line; then
                    line=$cur_line
                fi
                cv_window ${GBL[DB_FILE]} $line.$turn.$side
                line=$cur_line
                ;;
            DEFEN)
                cd_defenify DB
                cd_fenify DB $line
                save_db=true
                ;;
            DEBUG)  # DEBUG [true|false]
                if [[ -z ${args[1]} ]]; then
                    if ${UTIL[DEBUG]}; then
                        UTIL[DEBUG]=false
                    else
                        UTIL[DEBUG]=true
                    fi
                else
                    UTIL[DEBUG]=${args[1]}
                fi
                ;;
            ABORT)
                save_db=false
                return 1
                ;;
            \?)  :  # Help - falls through and is displayed below
                ;;
            *)      # Use alternate move to jump to another line
                move=${args[0]}
                if node_get -q DB $line.$turn.$side.a.$move tmp; then
                    hist+=($line.$turn.$side)
                    line=$tmp
                    if cd_fenify DB $line; then
                        save_db=true
                    fi
                elif [[ $(node_get DB $line.$turn.$side.m) == $move ]]; then
                    msg="Already on line with move '$move'"
                else
                    msg="Unrecognized command: $move"
                fi
                ;;
        esac

        cv_moves_and_board DB $line $turn $side $rotate

        if [[ -n ${GBL[ERR]} ]]; then
            echo -e "\n${GBL[ERR]}"
            GBL[ERR]=
        fi
        if [[ -n $msg ]]; then
            echo -e "\n$msg"
            msg=
        fi
        if [[ ${args[0]} == '?' ]]; then
            echo
            commands   # Help
        fi

        echo
    done

    # Done - save changes to DB
    if $save_db && ${GBL[SAVE_DB]}; then
        cd_save DB ${GBL[DB_FILE]}
    fi
    return 0
}


# Command line args
shopt -s extglob
while [[ -n $1 ]]; do
    case $1 in
        ?(-)-d*)
            UTIL[DEBUG]=true
            shift
            ;;
        ?(-)-s*)
            GBL[START]=$2
            shift 2
            ;;
        ?(-)-w*)
            GBL[SAVE_DB]=false
            shift
            ;;
        *)
            GBL[DB_FILE]=$1
            shift
            ;;
    esac
done

main
exit $?

# EOF
