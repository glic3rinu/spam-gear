#!/bin/bash

# USAGE:
#   bash php_fucker.sh INTERVAL_IN_MINUTES
#
# CRONTAB:
#   */10 * * * * /root/spam/php_fucker.sh MINUTES MAX_MAILS MAX_MAILS


MINUTES=$(echo "${1:-10}*1.2" | bc | sed "s/\..*//")
MAX_MAILS=${2:-10}
MAX_MAILS=${3:-500}


# PHP < 5.3 (No built-in mail logging support)
log=$(
    grep "sendmail-php" /var/log/mail.log | awk '$0>=from&&$0<=to' \
    from="$(date +%b" "%d" "%H:%M:%S -d -${MINUTES}minute | sed 's/ 0\([0-9]\) /  \1 /')" \
    to="$(date +%b" "%d" "%H:%M:%S | sed 's/ 0\([0-9]\) /  \1 /')" \
    | awk {'print $9'} | sed -s "s/.*=\(.*\),/\1/" | grep -v '^$' | sort | uniq -c
)
shit_found=$(
    while read line; do
        current=($(echo "$line"))
        if [[ ${current[0]} != "" && ${current[0]} -ge $MAX_MAILS ]]; then
            echo "${current[1]}"
        fi;
    done < <(echo -e "${log}")
)


# PHP >= 5.3 (timestamp NOT available)
log=$(grep ^mail /var/log/phpmail.log | cut -d':' -f1|cut -d'[' -f2 | sort | uniq -c)
shit_found53=$(
    while read line; do
        current=($(echo "$line"))
        if [[ ${current[0]} != "" && ${current[0]} -ge $MAX_DAILY_MAILS ]]; then
            echo "${current[1]}"
        fi;
    done < <(echo -e "${log}")
)


# TODO PHP >= 5.5 (timestamp IS available)

echo -e "${shit_found}\n${shit_found53}" | bash $(dirname "$0")/fuck_them_all.sh

