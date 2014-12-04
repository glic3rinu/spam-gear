# Spam-gear

Anti-spam artillery for your multi-user web and mail servers.

This project consists of a handful of tools that try to provide a good-enough solution to two unsolvable problems:

1. Spammers sending spam through compromised PHP web applications on shared hosting environments
2. Spammers sending spam via stolen e-mail credentials

Spam-gear scripts follow the UNIX philosophy of combining small tools that do one thing, and do it well.

We run them under Debian, don't know about compatibility with other distros.


## Installation
```bash
cd /root
git clone https://github.com/glic3rinu/spam-gear.git
```


## Contents

* [Log analyisis](logs) tools
    * [postfix-spam-check](logs/postfix-spam-check)
    * [exim-spam-check](logs/exim-spam-check)
    * [roundcube-spam-check](logs/roundcube-spam-check)
    * [imp-spam-check](logs/imp-spam-check)
    * [php-spam-check](logs/php-legacy-check)
    * [php-legacy-spam-check](logs/php-spam-legacy-check)
* [Filesystem scan] tools
    * [full-scan](scans/full-scan)
    * [clamd-client](scans/clamd-client)
    * [php-shell-detector](scans/php-shell-detector)
* [Utils](utils)
    * [emergency-mail](utils/emergency-mail)
    * [check_dnsbl.sh](utils/check_dnsbl.sh) Black list checker
    * [runav.sh](utils/runav.sh) full scan wrapper for modsecurity


## Crontab examples

This is how some of our crontabs look like:

```bash
# Web server crontab
PATH=${PATH}:/root/spam-gear/bin
SHELL=/bin/bash
0    * * * *   exim-spam-check 3600 90 | emergency-mail 2000
0,30 * * * *   roundcube-spam-check -p 1hour -m 60 -d 10,10 -n web.pangea.org | emergency-mail 3000
0,30 * * * *   imp-spam-check -p 1hour -m 60 -d 10,10 -n web.pangea.org | emergency-mail 3000
*/10 * * * *   { php-spam-legacy 10 10 && php-spam 500; } \
                | full-scan -q -n '^/home/pangea/\([^/.]*\)/.*' -c /root/spam-gear/scan/alerta_pangea.email
0    0 * * *   php-shell-detector --update
30   2 * * 6   find /home/pangea/ -type f -size -5M \
                | full-scan -q -n "^/home/pangea/\([^/.]*\)/.*" -c /root/spam-gear/scan/alerta_pangea.email
30   5 * * 0-5 find /home/pangea/ -type f -mtime -2 -iname "*php" \
                | full-scan -q -n "^/home/pangea/\([^/.]*\)/.*" -c /root/spam-gear/scan/alerta_pangea.email
```

```bash
# Mail server crontab

PATH=$PATH:/root/spam-gear/bin
0,30 * * * * postfix-spam-scan -p 1hour -m 90 -d 10,10 -n web.pangea.org -w 77.246.181.201,10.0.0.21 | emergency-mail 3000
```


## TODO
- Document using spam-gear with apache2-modsecurity:
    - 
- Threshold on number of recipients
