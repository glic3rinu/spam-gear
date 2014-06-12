#!/bin/bash

# USAGE:
#   find /home/pangea/ -mtime -2 -iname "*php" | bash fuck_them_all.sh


. $(dirname "$0")/config.sh


[[ ! -e "$QUARANTINE_DIR" ]] && mkdir "$QUARANTINE_DIR"


TMP_FILE=$(mktemp)
SHELLS_TIME=$(date +%s)
SHELLS=""
while read line; do
    # Lookup for common php shell patterns
    if [[ $(egrep "(@error_reporting\(0\); @ini_set\('error_log',NULL\); @ini_set\('log_errors',0\);|7X1re9s2z/Dn9VcwmjfZq\+PYTtu7s2MnaQ5t2jTpcugp6ePJsmxrkS1PkuNkWf77C4C)" "$line" 2> /dev/null) ]]; then
        mv "$line" "$QUARANTINE_DIR"
        SHELLS="${SHELLS}\n${line} [COMMON]"
    elif [[ $(grep '$x74\[41\].$x74\[71\].$x74\[10\].$x74\[96\].$x74\[12\].$x' "$line" 2> /dev/null) ]]; then
        mv "$line" "$QUARANTINE_DIR"
        SHELLS="${SHELLS}\n${line} [COMMON]"
    else
        # Cleanup possible backdoors
        if [[ $(grep '<?php\s*eval\s*(\s*base64_decode\s*(\s*$_POST\['"'"'[0-z]*'"'"'\]));?>' "$line" 2> /dev/null) ]]; then
            sed -i 's/<?php\s*eval\s*(\s*base64_decode\s*(\s*$_POST\['"'"'[0-z]*'"'"'\]));?>//g' "$line" 2> /dev/null
            SHELLS="${SHELLS}\n${line} [BACKDOOR]"
	elif [[ $(grep 'eval\s*(\s*base64_decode.*_POST' "$line" 2> /dev/null) ]]; then
            SHELLS="${SHELLS}\n${line} [NON-CLEANED BACKDOOR]"
        fi
        [[ "$line" != "" ]] && echo "$line"
    fi;
done > "$TMP_FILE"


CLAM_TIME=$(date +%s)
if [[ -s "$TMP_FILE" ]]; then
    # clamscan is not able to read a list of files from stdin, WTF!
    while read line; do
        mv "$line" "$QUARANTINE_DIR"
        SHELLS="${SHELLS}\n${line} [CLAMSCAN]"
    done < <(clamscan -i -f "$TMP_FILE" 2>&1 | grep FOUND | cut -d':' -f1)
fi

rm -f "$TMP_FILE"

if [[ "$SHELLS" ]]; then
    CLAM_TIME=$(($(date +%s) - $CLAM_TIME))
    SHELLS_TIME=$(($(date +%s) - $SHELLS_TIME))
    
    echo -e "$SHELLS"
    echo -e "\n--------------------------"
    echo "CLAM TIME: $CLAM_TIME seconds"
    echo "SHELLS TIME: $SHELLS_TIME seconds"
    echo "TOTAL TIME: $(($CLAM_TIME+$SHELLS_TIME)) seconds"
    exit 1
fi


exit 0

