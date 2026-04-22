#!/usr/bin/env bash

set -euo pipefail

output_file="/home/jaennil/obs-time.txt"

while true; do
    date "+%H:%M:%S" >"$output_file"
    sleep 1
done
