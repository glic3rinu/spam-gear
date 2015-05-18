# Utils

## [emergency-mail](emergency-mail)

Sometimes during spam attacks your local mail queue is badly saturated with tons of spam, potentially creating large delays on mail delivery, including alerts sent by the awesome spam-gear scripts :).

To avoid reciving delayed spam alerts this script opens an SMTP connection to a remote server and sends the report through it. But to avoid spamming your personal email account, it only does so when the local queue contains more than `EMERGENCY_THRESHOLD` messages.


This script is particularly useful combined with `postfix-spam-scan` or `exim-spam-scan`.

#### Installation

In order to use this script you should copy [`emergency-settings.example`](emergency-settings.example) to `emergency-settings` and configure the emergency servers and addresses.


#### Usage
    emergency-mail [EMERGENCY_THRESHOLD]

#### Examples
    postfix-spam-scan 1hour 90 | emergency-mail 3000



## [check_dnsbl.sh](check_dnsbl.sh)

Nagios check for most common DNSBL lists.


## [runav.sh](runav.sh)

Add a similar rule to `modsecurity.conf` config file:
```
SecRule FILES_TMPNAMES "@inspectFile /usr/local/share/spam-gear/utils/runav.sh" \
    "id:159,phase:2,t:none,log,deny,msg:'Malicious Code Detected, access denied'"
```

Be aware that the path where you have spam-gear `runav.sh` script should be accessible by Apache user (`www-data`).
