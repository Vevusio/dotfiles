#!/bin/bash

## Input parser for i3 bar
##
## Based on Electro7's work
## Modded by demure

## config
. $(dirname $0)/i3_lemonbar_config

## min init
irc_n_high=0
title="%{F${color_head} B${color_sec_b2}}${sep_right}%{F${color_head} B${color_sec_b2}%{T2} ${icon_prog} %{F${color_sec_b2} B-}${sep_right}%{F- B- T1}"

## parser
while read -r line ; do
	case $line in
		### SYS Case ### {{{
		SYS*)
			## conky=, 0=day, 1=month, 2=time, 3=cpu, 4=mem, 5=disk


			sys_arr=(${line#???})
            conky_val_day=${sys_arr[0]}
            conky_val_month=${sys_arr[1]}
            conky_val_time=${sys_arr[2]}
            conky_val_cpu=${sys_arr[3]}
            conky_val_mem=${sys_arr[4]}
            conky_val_disk=${sys_arr[5]}

			### Time and Date ### {{{
			## Date
			date="%{F- B- T2}${icon_clock}%{F- B- T1} ${conky_val_day}.${conky_val_month}"
			## Time
			time="%{F- B-}${conky_val_time} %{F- B- O19}"
			### End Time ### }}}

			### CPU ### {{{
			printf -v CPU_PERCENT_FORMATTED "%2d%%" "${conky_val_cpu}"
			cpu="%{F- B- T2}${icon_cpu}%{T1} ${CPU_PERCENT_FORMATTED}"
			### End CPU ### }}}

			### Memory and Disk ### {{{
			## mem (ram)
			printf -v MEM_PERCENT_FORMATTED "%2d%%" "${conky_val_mem}"
			mem="%{F- B- T2}${icon_mem}%{T1} ${MEM_PERCENT_FORMATTED}"
			## disk /
			#diskr="%{F- B- T2}${icon_hd}%{T1} ${conky_val_disk}"
			### End Memory ### }}}
			;;
		### End SYS Case ### }}}

		### Volume Case ### {{{
		VOL*)
			## Volume
			vol_arr="${line#???}"
			vol="%{F- B- T2}${icon_vol}%{T1} ${vol_arr}"
			;;
		### End Volume Case ### }}}

		### Brightness Case ### {{{
		BRI*)
			## Brightness
			bright_arr="${line#???}"
			
			## Don't show brightness if there is no battery.
			## Most desktops don't software adjust brightness.
			## I suppose there is a small use case[<35;223;26[<35;169;26]] of a laptop with no battery...
			if [ "${bright_arr}" != "none" ]; then
				bri="%{F- B- T2}${icon_bri}%{T1} ${bright_arr}%"
			  else
				bri=""
			fi
			;;
		### End Brightness Case ### }}}

		### Thinkpad Multi Battery ### {{{
		## Icon         0         1         2         3          4
		## Bat >=      NA        11        37        63         90
		## Range     0-10     11-36     37-62     63-89     90-100

		TMB*)
			## Now that I have >12 hours of battery, I don't feel the need for as drastic color thresholds.
			## I will have colors only at much lower percentages.

			tmb_arr_perc=$(echo ${line#???} | cut -f1 -d\ )
			tmb_arr_stat=$(echo ${line#???} | cut -f2 -d\ )
			tmb_arr_time=$(echo ${line#???} | cut -f3 -d\ )

			## This means it will not show up on desktop computers
			if [ "${tmb_arr_perc}" != "none" ]; then
				## Set icon only
				## This is 'hard' coded, instead of in the conf, due to icon font.
				## It will take user intervention if they have a different number of icons
				if [ ${tmb_arr_perc} -ge 90 ]; then
					bat_icon=${icon_bat4};
				elif [ ${tmb_arr_perc} -ge 63 ]; then
					bat_icon=${icon_bat3};
				elif [ ${tmb_arr_perc} -ge 37 ]; then
					bat_icon=${icon_bat2};
				elif [ ${tmb_arr_perc} -ge 11 ]; then
					bat_icon=${icon_bat1};
				else
					bat_icon=${icon_bat0};
				fi

				## Set Colors
				if [ ${tmb_arr_perc} -le ${bat_alert_low} ]; then
					bat_cicon=${color_icon}; bat_cfore=${color_fore}; bat_cback=${color_bat_low};
				elif [ ${tmb_arr_perc} -le ${bat_alert_mid} ]; then
					bat_cicon=${color_icon}; bat_cfore=${color_fore}; bat_cback=${color_bat_mid};
				elif [ ${tmb_arr_perc} -le ${bat_alert_high} ]; then
					bat_cicon=${color_bat_high}; bat_cfore=${color_fore}; bat_cback=${color_sec_b1};
				else
					bat_cicon=${color_icon}; bat_cfore=${color_fore}; bat_cback=${color_sec_b1};
				fi

				## Set charging icon
				if [ "${tmb_arr_stat}" == "C" ]; then
					bat_icon=${icon_bat_plug}; bat_cicon=${color_bat_plug};
				fi
				bat="%{F${bat_cback}}${sep_left}%{F${bat_cicon} B${bat_cback}}%{T2}${bat_icon}%{F- T1} ${tmb_arr_perc}%"
				
				if [ "${tmb_arr_time}" != "none" ]; then
					bat_time="%{F${color_icon}}${sep_l_left}%{F${color_icon} B${color_sec_b1}} %{T2}${icon_bat_time}%{F- T1} ${tmb_arr_time}"
				  else
					bat_time=""
				fi
			  else
				bat=""
			fi
			;;
		### End Thinkpad Multi Battery ### }}}

		### Workspace Case ### {{{
		WSP*)
			## I3 Workspaces
			wsp="%{F- B- O19 T2}${icon_wsp}%{T1 O19}"
			set -- ${line#???}
			while [ $# -gt 0 ] ; do
				case $1 in
				 FOC*)
					wsp="${wsp}%{F- B${color_workspace_selected_bg} T1}%{+u}  ${1#???}  %{-u}%{B-}"
					;;
				 INA*|URG*|ACT*)
					wsp="${wsp}%{F- B- T1}  ${1#???}  "
					;;
				esac
				shift
			done
			wsp="${wsp}%{O19}"
			;;
		### End Workspace Case ### }}}

		### Window Case ### {{{
		WIN*)
			## window title
			title=$(xprop -id ${line#???} | awk '/_NET_WM_NAME/{$1=$2="";print}' | cut -d'"' -f2)
			title="%{F- B- T2}${icon_prog}%{T1} ${title}"
			;;
		### End Window Case ### }}}
	esac

	### Network Display Toggle ### {{{
	# This is toggled by, preferably, a binding in your ~/.i3/config
	## You can find the awk command in my config, or this bar's readme

	ext_toggle="$(cat /tmp/i3_lemonbar_ip_${USER} 2>/dev/null)"

	if [ "${ext_toggle}" = 2 ]; then
		local_ip="%{F${color_sec_b1}}${sep_left}%{F${color_icon} B${color_sec_b1}} %{T2}${net_icon}%{F- T1} ${scrub_ip}"
		filler="%{F${color_sec_b2}}${sep_left}%{F${color_icon} B${color_sec_b2}} %{T2}${icon_ext_ip}%{F- T1}"
		mast_net="${local_ip}${stab}${wifi}${stab}${filler}${stab}${vpn}${stab}"
	  elif [ "${ext_toggle}" = 1 ]; then
		if [ "${net_arr_ipv6}" = "none" ]; then
			net_arr_ipv6="No IPv6"
		fi

		filler="%{F${color_sec_b1}}${sep_left}%{F${color_icon} B${color_sec_b1}} %{T2}${net_icon}%{F- T1}"
		ext_ip="%{F${color_sec_b2}}${sep_left}%{F${color_icon} B${color_sec_b2}} %{T2}${icon_ext_ip}%{F- T1} ${net_arr_ipv6}"
		mast_net="${filler}${stab}${ext_ip}"
	  else
		mast_net="${local_ip}${stab}${wifi}${stab}${ext_ip}${stab}${vpn}${stab}"
	fi
	### End Network Display Toggle ### }}}

	## And finally, output
	## Broken into multiple lines to make more readable.
	## You can rearrange them or remove them as desired.
	## Notice that all but the first and last have a ${stab} for spacing.

	## NOTE: At this moment, there is not a dead simple way to adjust a
	# segment between the three background colors, you have to manually
	# find the CASE and edit.

	printf "%s" "%{l}${wsp}${title} "

	printf "%s" "%{r}"
    if [ ! -z "${mast_net}" ]; then
        printf "%s" "${mast_net}${stab}"
    fi
    if [ ! -z "${bat}" ]; then
        printf "%s" "${bat}${stab}"
    fi
    if [ ! -z "${bat_time}" ]; then
        printf "%s" "${bat_time}${stab}"
    fi
    if [ ! -z "${cpu}" ]; then
        printf "%s" "${cpu}${stab}"
    fi
    if [ ! -z "${mem}" ]; then
        printf "%s" "${mem}${stab}"
    fi
    if [ ! -z "${diskr}" ]; then
        printf "%s" "${diskr}${stab}"
    fi
    if [ ! -z "${nets_d}" ]; then
        printf "%s" "${nets_d}${stab}"
    fi
    if [ ! -z "${nets_u}" ]; then
        printf "%s" "${nets_u}${stab}"
    fi
    if [ ! -z "${vol}" ]; then
        printf "%s" "${vol}${stab}"
    fi
    if [ ! -z "${bri}" ]; then
        printf "%s" "${bri}${stab}"
    fi
    if [ ! -z "${date}" ]; then
        printf "%s" "${date}${stab}"
    fi
    if [ ! -z "${time}" ]; then
        printf "%s" "${time}"
    fi

    printf "\n"

done
