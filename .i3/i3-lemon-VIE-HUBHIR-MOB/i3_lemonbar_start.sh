#!/bin/bash

if [ $(pgrep -cx 'i3_lemonbar.sh') -gt 1 ] ; then
    killall i3_lemonbar.sh
fi

exec $(dirname $0)/i3_lemonbar.sh