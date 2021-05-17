#!/usr/bin/bash

<<'__NOTES__'

Configuration Customizations

Use is file for setting/modifying an configuration parameters for COSA.

__NOTES__

# For board that displays UNICODE chess pieces
FANCY_BOARD=true
# For plain text
#FANCY_BOARD=false


# Stockfish location
#ENG[ENG]=$HOME/games/stockfish/stockfish

# If you don't have Stockfish
#unset 'ENG[ENG]'


# For 'Open line in new window' command...
# ... if using X
#WINDOW_CMD='xterm -e %s'
#WINDOW_BKG=true

# .. if you're using XFCE, try this:
#WINDOW_CMD='xfce4-terminal --zoom=2 --geometry=56x58 -x %s'
#WINDOW_BKG=true

# EOF
