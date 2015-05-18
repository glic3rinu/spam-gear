#!/bin/bash

# Modsecutiry2 compat wrapper for full-scan

filename=$1
echo $filename | "$(dirname $(readlink -f "$0"))/../bin/full-scan" &> /dev/null
found=$?

if [[ $found -eq 0 ]]; then
    echo "1 clamscan: OK"
else
    echo "0 clamscan: FOUND"
fi
