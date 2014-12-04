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

PATH=$PATH:/root/spam-gear/bin
0    * * * *   exim-spam-scan 3600 60 | emergency-mail 2000
*/10 * * * *   { php-spam-legacy 10 10 && php-spam 500; } | php-shell-scan -q
0    0 * * *   php-shell-detector updatedb

# For us this is very expensive because our home is mounted from a SAN and
# transversal reads of the whole FS invalidates most of the FS cache :(
php_shell_scan="php-shell-scan -q -n '^/home/pangea/\([^/.]*\)/.*' -c /root/spam-gear/user_alert.email"
30   2 * * 6   find /home/pangea -type f | ${php_shell_scan}
30   5 * * 0-5 find /home/pangea/ -mtime -2 -iname "*php" | ${php_shell_scan}
```

```bash
# Mail server crontab

PATH=$PATH:/root/spam-gear/bin
0 * * * * postfix-spam-scan -m 90 -d 10,10 -n auth.ourdomain.org | emergency-mail 3000
```


## TODO
- Document using spam-gear with apache2-modsecurity:
    - 
- Threshold on number of recipients
