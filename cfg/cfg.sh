#!/bin/bash

<<'__NOTES__'

Your preference should be to leave this file as is, and
put your configuration customizations in cfg/my_cfh.sh.

__NOTES__


COSA_VERSION='0.1.0'

UTILS_MISC=true
. $COSA/lib/utils_misc
UTILS_TREE=true
. $COSA/lib/utils_tree

. $COSA/lib/db.sh
. $COSA/lib/move.sh
. $COSA/lib/view.sh
. $COSA/lib/engine.sh


# For the 'win' command within COSA.  (Customize in cfg/my_cfg.sh.)
WINDOW_CMD='%s'
WINDOW_BKG=false


declare -A GBL=(
    [DB_FILE]=
    [START]=
    [READONLY]=false
    [ERR]=
    [MSG]=
)


# Engine parameters
declare -A ENG=(
    # Configure in cfg/my_cfg if different
    [ENG]=/usr/games/stockfish

    [TO]=$COSA/tmp/stockfish_cmd.fifo
    [FM]=$COSA/tmp/stockfish_out.fifo
    [LOG]=$COSA/log/stockfish.log

    # These can be overridden in cfg/my_cfg.sh, and
    # changed using the 'params' command within COSA
    [depth]=25
    [/Threads]=$(grep -c ^processor /proc/cpuinfo)
    [/Hash]=$(grep MemTotal /proc/meminfo | awk '{print int($2/2000)}')
    [/MultiPV]=5
    [/Contempt]=100

    [KILL_TIME]=3
    [SHOW]=false
)


# Finally, load configuration customizations
. $COSA/cfg/my_cfg.sh

# EOF
