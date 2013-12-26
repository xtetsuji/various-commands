#!/bin/bash
# even-week.sh
#   if this week is even, exit code returns 0,
#   else this week is odd, exit code returns 1.

day=$1
if [ -z "$day" ] ; then
    day=today
fi

if [[ $(( $( date +%U -d "$day" ) % 2 )) == 0 ]] ; then 
    exit 0
else
    exit 1
fi
