#!/bin/bash

## I3 bar with https://github.com/LemonBoy/bar
##
## Based on Electro7's work
## Modded by demure

. $(dirname $0)/i3_lemonbar_config

if [ $(pgrep -cx $(basename $0)) -gt 1 ] ; then
	printf "%s\n" "The status bar is already running." >&2
	exit 1
fi

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

[ -e "${panel_fifo}" ] && rm "${panel_fifo}"
mkfifo "${panel_fifo}"

### monitors
### connected and active, will contain string like " connected 1920x..."
### formatted as {left-x-coord}={output-name}, sorted by x-coord, output-names joined as whitespace csv
### in the end monitors is contains output-names separated by whitespaces, in the order that lemonbar understands
### i.e. output index 0 = lemonbar %{S0}, output index 1 = %{S1}, etc.
monitors=$(xrandr \
    | awk '/[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {resolutionAndPosition=($3!="primary") ? $3 : $4; print gensub(/^[^\+]+\+([0-9]+)\+.*$/, "\\1", "g", resolutionAndPosition)"="$1}' \
    | sort -t '=' -k 1 -n \
    | awk -F '=' '{print $2}' \
    | paste -sd " ")
printf "MON%s\n" "${monitors}" > "${panel_fifo}" &

## Window title, "WIN"
xprop -spy -root _NET_ACTIVE_WINDOW | sed -un 's/.*\(0x.*\)/WIN\1/p' > "${panel_fifo}" &

## i3 Workspaces, "WSP"
## TODO : Restarting I3 breaks the IPC socket con. :(
$(dirname $0)/i3_workspaces.pl > "${panel_fifo}" &

## Conky, "SYS"
conky -c $(dirname $0)/i3_lemonbar_conky > "${panel_fifo}" &

### UPDATE INTERVAL METERS
cnt_vol=${upd_vol}
cnt_bri=${upd_bri}
cnt_tmb=${upd_tmb}

while :; do

	## Volume, "VOL"
	if [ $((cnt_vol++)) -ge ${upd_vol} ]; then
		amixer get Master | awk -F'[]%[]' '/%/ {STATE=$5; VOL=$2} END {if (STATE == "off") {print "VOL×\n"} else {printf "VOL%d%%\n", VOL}}' > "${panel_fifo}" &
		cnt_vol=0
	fi

	## Brightness, "BRI"
	if [ $((cnt_bri++)) -ge ${upd_bri} ]; then
        CAN_READ_BRIGHTNESS=false
        for f in /sys/class/brightness/*; do
            if [ -e "$f" ]; then
                CAN_READ_BRIGHTNESS=true
            fi
            break
        done

        if [ $CAN_READ_BRIGHTNESS == true ]; then
            ## xbacklight doesn't work as this doesn't have xrandr access while running as the bar?
            ## On failure, '$1/$2' becomes '0', and will result in 'none'
            printf "%s%s\n" "BRI" "$(paste /sys/class/backlight/*/{actual_brightness,max_brightness} | awk '{BRIGHT=$1/$2*100} END {if(BRIGHT!=0){printf "%.f", BRIGHT} else {print "none"}}')" > "${panel_fifo}"
            cnt_bri=0
        fi
	fi

	## Thinkpad Milti Battery, "TMB"
	## Works for normal batteries now too.
	if [ $((cnt_tmb++)) -ge ${upd_tmb} ]; then
		## Check for BAT0
		if [ -e /sys/class/power_supply/BAT0/uevent ]; then
			BAT0="/sys/class/power_supply/BAT0/uevent"
		  else
			BAT0=""
		fi

		## Check for BAT1
		if [ -e /sys/class/power_supply/BAT1/uevent ]; then
			BAT1="/sys/class/power_supply/BAT1/uevent"
		  else
			BAT1=""
		fi

		if [ "${BAT0}" != "" ] || [ "${BAT1}" != "" ]; then
			## Originally "/sys/class/power_supply/BAT{0..1}/uevent" but changed into variables make work for non thinkpad cases. paste fails if it can't find a passed file.
			## "U" for unknown
			printf "%s%s %s\n" "TMB" "$(paste -d = ${BAT0} ${BAT1} 2>/dev/null | awk 'BEGIN {CHARGE="U"} /ENERGY_FULL=/||/ENERGY_NOW=/||/STATUS=/||/CHARGE_NOW=/||/CHARGE_FULL=/ {split($0,a,"="); if(a[2]~/Discharging/||a[4]~/Discharging/){CHARGE="D"} else if(a[2]~/Charging/||a[4]~/Charging/){CHARGE="C"} else if (a[2]~/Full/||a[4]~/Full/){CHARGE="F"}; if(a[1]~/FULL/){FULL=a[2]+a[4]}; if(a[1]~/NOW/){NOW=a[2]+a[4]};} END {if(NOW!=""){PERC=int((NOW/FULL)*100)} else {PERC="none"}; printf("%s %s\n", PERC, CHARGE)}')" "$(acpi -b | awk '/[0-9][0-9]:[0-9][0-9]:[0-9][0-9] (until|remaining)/ {if($5!=""){TIME=$5}i} END {if(TIME!=""){print TIME} else {print "none"}}')" > "${panel_fifo}" 
			else
			printf "%s%s\n" "TMB" "none" > "${panel_fifo}"
		fi
		cnt_tmb=0
	fi

	## Finally, wait 1 second
	sleep 1s;

done &

#### LOOP FIFO

cat "${panel_fifo}" | $(dirname $0)/i3_lemonbar_parser.sh \
	| lemonbar -b -p -f "${font}" -f "${iconfont}" -g "${geometry}" -B "${color_back}" -F "${color_fore}" -U "${color_underline}" -u "${pixels_underline}" &

wait

