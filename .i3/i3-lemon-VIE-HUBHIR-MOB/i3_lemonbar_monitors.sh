#!/bin/bash

printMonitorStatus() {
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
    printf "MON%s\n" "${monitors}"
}

printMonitorStatus

while read -r line ; do
    printMonitorStatus
done < <(tail -F -n 1 '/tmp/output_changes' 2>/dev/null )

