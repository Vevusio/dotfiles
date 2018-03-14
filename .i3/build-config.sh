#!/usr/bin/env bash
ETC_HOSTNAME=$(cat /etc/hostname)
I3_REAL_CONFIG="$HOME/.i3/config"
I3_NEXT_CONFIG="$HOME/.i3/config.tmp"

rm -f ${I3_NEXT_CONFIG}
touch ${I3_NEXT_CONFIG}

for config in $HOME/.i3/config.d/*; do
    if [[ $config == *-host.config ]]
    then
        if [[ $config == *-${ETC_HOSTNAME}-host.config ]]
        then
            cat $config >> ${I3_NEXT_CONFIG}
            echo "" >> ${I3_NEXT_CONFIG}
        fi
    else
        cat $config >> ${I3_NEXT_CONFIG}
        echo "" >> ${I3_NEXT_CONFIG}
    fi
done

mv ${I3_NEXT_CONFIG} ${I3_REAL_CONFIG}
sleep 1