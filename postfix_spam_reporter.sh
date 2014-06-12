#!/bin/bash

# USAGE:
#   bash postfix_spam_reporter.sh [--emergency-email [<EMERGENCY_THRESHOLD>]]

. $(dirname "$0")/utils.sh
. $(dirname "$0")/config.sh


log=$(
    grep "sasl_username=" /var/log/mail.log | awk '$0>=from&&$0<=to' \
    from="$(date +%b" "%d" "%H:%M:%S -d -$PERIOD | sed 's/ 0\([0-9]\) /  \1 /')" \
    to="$(date +%b" "%d" "%H:%M:%S | sed 's/ 0\([0-9]\) /  \1 /')" \
)

spammers=""
while read line; do
    current=($(echo "$line"))
    if [[ ${current[0]} != "" && ${current[0]} -ge $MAX_CONNECTIONS ]]; then
        userlogs=$(echo "$log" | grep "sasl_username=${current[1]}")
        logentry=$(echo "$userlogs" | head -n1)
        numips=$(echo "$userlogs" | cut -d'[' -f3 | cut -d']' -f1 | sort | uniq | wc -l)
        unknown=$(echo "$userlogs" | grep 'client=unknown\[' | cut -d'[' -f3 | cut -d']' -f1 | sort | uniq | wc -l)
        nets=$(echo "$userlogs" | cut -d'[' -f2 | cut -d'=' -f2 | sed "s/.*[0-9].//" | sort | uniq | wc -l)
        spammers="${spammers}\n${current[0]} (${nets} nets/${unknown} unknown/${numips} IPs) -- ${logentry}"
    fi;
done < <(echo "$log" | cut -d'=' -f4 | sort -n | uniq -c)


[[ "$spammers" == "" ]] && exit 0

period=$(echo $PERIOD | sed "s/\([0-9]*\)/\1 /")
message="During the last $period the following senders have made at least $MAX_CONNECTIONS SMTP connections."
message="${message}\n\n${spammers}"
echo -e "$message"

MAILQ=$(mailq | tail -n1| awk {'print $5'})
if [[ "$EMERGENCY_MAIL" != "" && $MAILQ -gt $EMERGENCY_TRESHOLD ]]; then
    send_emergency_mail $message
fi

exit 1

