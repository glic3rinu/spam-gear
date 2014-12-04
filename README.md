# Spam-gear

Anti-spam artillery for your multi-user web and mail servers.

This project consists of a handful of tools that, once combined, provide a good enough solution to two unsolvable problems.

1. Spammers sending spam through compromised PHP web applications on shared hosting environments
2. Spammers sending spam via stolen e-mail credentials


## Installation
```bash
cd /root
git clone https://github.com/glic3rinu/spam-gear.git
```


## Contents
* [Log analyisis tools](logs) - Identify and stop spammers by looking at log files
    * [postfix-spam-check](logs/postfix-spam-check)
    * [exim-spam-check](logs/exim-spam-check)
    * [roundcube-spam-check](logs/roundcube-spam-check)
    * [imp-spam-check](logs/imp-spam-check)
    * [php-spam-check](logs/php-legacy-check)
    * [php-legacy-spam-check](logs/php-spam-legacy-check)
* [Filesystem scan tools](scans) - Detect and remove malicious code from your system
    * [full-scan](scans/full-scan) - Wrapper for clamd-client and php-shell-detector
    * [clamd-client](scans/clamd-client) - Python client for [Clamd](http://www.clamav.net)
    * [php-shell-detector](scans/php-shell-detector) - Rewrite of [Shell-Detector](https://github.com/emposha/Shell-Detector)
* [Utils](utils) - Miscellaneous directory
    * [emergency-mail](utils/emergency-mail) - SMTP client for sending emails outside
    * [check_dnsbl.sh](utils/check_dnsbl.sh) - Nagios black list checker
    * [runav.sh](utils/runav.sh) - full-scan wrapper for modsecurity


## Crontab examples
This is how some of our crontabs look like:

```bash
# Web server crontab
PATH=${PATH}:/root/spam-gear/bin
SHELL=/bin/bash
FULL_SCAN="full-scan --quarantine --custom-email /root/spam-gear/scan/alert.email"
0    * * * *   exim-spam-check --period 1hour --max-connections 90 | emergency-mail 2000
0,30 * * * *   roundcube-spam-check -p 1hour -m 60 --disable 10,10 --nis localhost \
                | emergency-mail 3000
0,30 * * * *   imp-spam-check -p 1hour -m 60 --disable 10,10 --nis localhost \
                | emergency-mail 3000
*/10 * * * *   { php-spam-legacy 10 10 && php-spam 500; } | $FULL_SCAN
0    0 * * *   php-shell-detector --update
30   2 * * 6   find /home/pangea/ -type f -size -5M | $FULL_SCAN
30   5 * * 0-5 find /home/pangea/ -type f -mtime -2 -iname "*php" | $FULL_SCAN
```

```bash
# Mail server crontab
PATH=$PATH:/root/spam-gear/bin
0,30 * * * * postfix-spam-scan -p 1hour -m 90 -d 10,10 -n nis.example.org -w 10.26.181.21,10.0.0.21 \
                | emergency-mail 3000
```
