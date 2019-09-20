#!/bin/bash

UTILS_MISC=true
UTILS_TREE=true
#. $COSA/bin/utils
. $COSA/lib/utils_misc
. $COSA/lib/utils_tree

#UTIL[LIB]=$(realpath ${UTIL[DIR]}/../lib)
UTIL[DAT]=$(realpath ${UTIL[DIR]}/../dat)

. ${UTIL[LIB]}/db.sh
. ${UTIL[LIB]}/move.sh
. ${UTIL[LIB]}/view.sh
. ${UTIL[LIB]}/engine.sh
#. ${UTIL[LIB]}/png.sh


<<'__NOTES__'

__NOTES__

# EOF
