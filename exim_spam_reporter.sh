#!/bin/bash
# USAGE:
#   bash exim_spam_reporter.sh [--emergency-email [<EMERGENCY_THRESHOLD>]]


. $(dirname "$0")/utils.sh
. $(dirname "$0")/config.sh


log=$(grep '<=' /var/log/exim4/mainlog | awk 'BEGIN {
    # Get time in seconds the script is run
    now=systime()
    current = strftime("%y:%m:%d:%H:%m:%S",now)
    print "Current date/time is: "current
    onehr = 3600 # Seconds in 1 hr
} {
    column1=$1
    column2=$2
    m=split(column1,date,"-")
    n=split(column2,time,":")
    year=date[1] ; mth=date[2] ; day=date[3]
    hr=time[1] ; min=time[2] ; sec=time[3]
    # Prepare to pass to mktime() function
    t=sprintf("%s %s %s %s %s %s" , year,mth,day,hr,min,sec)
    log_entry_time = mktime(t)
    if ( now - log_entry_time <= onehr ){
        # If less than one hour
        print $0
    }
}')

# USER based
spammers=""
while read line; do
    current=($(echo "$line"))
    if [[ ${current[0]} != "" && ${current[0]} -gt $MAX_CONNECTIONS ]]; then
        logentry=$(echo "$log" | grep "U=${current[1]} "|head -n1)
        spammers="${spammers}\n${current[0]} -- ${logentry}"
    fi;
done < <(echo "$log" | grep 'U=' | awk -F'U=' {'print $2'} | awk {'print $1'} | sort | uniq -c)


# HOST based
while read line; do
    current=($(echo "$line"))
    if [[ ${current[0]} != "" && ${current[0]} -gt $MAX_CONNECTIONS ]]; then
        logentry=$(echo "$log" | grep "\(${current[1]}\)" | head -n1)
        spammers="{$spammers}\n${current[0]} -- ${logentry}"
    fi;
done < <(echo "$log" | grep -v 'U=' | awk -F'(' {'print $2'} | cut -d')' -f1 | sort | uniq -c)


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

