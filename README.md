# Spam-gear

Anti-spam artillery for your multi-user web and mail servers.

This project consists of a handful of tools that try to provide a good-enough solution to two unsolvable problems:

1. Spammers sending spam through compromised PHP web applications on shared hosting environments
2. Spammers sending spam via stolen e-mail credentials

Spam-gear scripts follow the UNIX philosophy of combining small tools that do one thing, and do it well.

These scripts don't have dependencies other than standard UNIX commands, Bash and Python. With the only exception of [php-shell-scan](#php-shell-scan), that uses clamscan under the hood.

We run them under Debian, don't know about compatibility with other distros.


### Installation
```bash
cd /root
git clone https://github.com/glic3rinu/spam-gear.git
```

## [postfix-spam-scan](postfix-spam-scan)


Scans Postfix logs `/var/log/mail.log` looking for SASL authenticated users that make
more than `MAX_CONNECTIONS` per time `PERIOD`. Covering the typical attacks on a mail server setup.

It can disable users based on the number of connections from different and unknown networks. Which is a very distinguishable pattern of mails sent from a botnet.

#### Usage
    postfix-spam-scan [OPTIONS]


#### Options
    -p, --period=PERIOD
        A DATE STRING compatible period "1hour" or "10minute" see man date for more.
        Defaults to "1hour"
    
    -m, --max-connections=MAX_CONNECTIONS
        Threshold value for number of connections beyond a report is made.
        Defaults to 90.
    
    -d, --dissable-account=MAX_NETWORKS,MAX_UNKNOWNS
        Specifies the boundary conditions for the maximum number of networks and unknown IPs
        beyond which the user account is automatically disabled.
        A separated e-mail is sent when a user is disabled so you don't miss it.
        Dissabling accounts is switched off by default.
    
    -n, --niss=[MASTER_SERVER]
        Disables a NIS account rather than a local account.
        It usses SSH and NIS MASTER_SERVER defaults to localhost.
    
    h, --help
        Shows help message

#### Examples
    postfix-spam-scan
    postfix-spam-scan -p 30minutes -m 60
    postfix-spam-scan -d 10,10



## [exim-spam-scan](exim-spam-scan)


Scans Exim4 logs under `/var/log/exim/mainlog` looking for *local users* and *SMTP connections*
that exceed `MAX_CONNECTIONS` during the last `SECONDS`. Covering the typical attacks on a shared hositing web server setup.

#### Usage
    exim-spam-scan [SECONDS] [MAX_CONNECTIONS]

#### Examples
    exim-spam-scan 3600
    exim-spam-scan 3600 60


## [php-shell-scan](php-shell-scan)

This is anti PHP shells heavy weaponry. It combines custom fingerprints and regular expressions, Clamscan and [PHP-Shell-Dectector](http://www.shelldetector.com/), all within one single shot. It can disable malicious files by moving them into a `QUARANTINE_DIR` and remove common PHP backdooring code as well as alert infected users via customized e-mails.

A rewrite of the [Python version](https://github.com/emposha/Shell-Detector) of PHP-Shell-Dectector is included in this package ([php-shell-detector](php-shell-detector)). Motivated because the original implementation just crashed when tested it through our PHP shells collection, the output was hard to parse and it had no support for inspecting specific files (only dirs). And guess what? it turned out to be x10 faster than the original implementation ;).


#### Usage
    find . | php-shell-scan [ OPTION ]

#### Options
    -q, --quarantine=[QUARANTINE_DIR]
        Moves infected files into QUARANTINE_DIR, which defaults to /root/shells
    
    -n, --notify-user=[USERNAME_PATTERN]
        Send a notification mail to the user when a shell has been detected on her home
        USERNAME_PATTERN defaults to '^/home/\([^/.]*\)/.*'
    
    -c, --custom-email=EMAIL_PATH
        Optional path to look for a custom email for user notification.
        Uses `default_shell_nofification.email` by default.
        Environemnt variables available on the email are:
            ${EMAIL}, ${USERNAME} and ${SHELLS}
    
    -h, --help
        Shows help text

#### Examples
    find /home/ -type f | php-shell-scan
    find /home/ -type f | php-shell-scan -q
    find /home/ -iname "*php" | php-shell-scan -q /dev/null


## [php-spam](php-spam)

With PHP &ge; 5.3 there is this feature that you can enable for logging emails sent via PHP. This can be done 
by setting `mail.log = /var/log/phpmail.log` on `php.ini`. Don't forget to rotate this new log file.


This script inspects `/var/log/phpmail.log` and returns the PHP scripts that exceed `MAX_DAILY_MAILS`.

Usually you want to run this script combined with `php-shell-scan` and `php-spam-legacy`.

#### Usage
    php-spam [MAX_DAILY_MAILS]

#### Examples
    php-spam
    php-spam 100
    php-spam 500 && php-spam-legacy 10 10



## [php-spam-legacy](php-spam-legacy)

This script is for legacy versions of PHP (&lt; 5.3), it inspects `/var/log/mail.log` and returns PHP scripts that exceed `MAX_MAILS` over the last number of `MINUTES`.

Usually you want to run this script combined with `php-shell-scan` and `php-spam`.


#### Usage
    php-spam-legacy [MINUTES] [MAX_MAILS]

#### Examples
    php-spam-legacy
    php-spam-legacy 10 30
    php-spam-legacy 10 10 && php-spam 500


#### System configuration

PHP prior to 5.3 has no built-in support for logging PHP scripts that send email. However, this can be done by creating a wrapper around sendmail command.

First create a `/usr/local/bin/phpsendmail` file with the following content
```bash
#!/bin/bash
logger -p mail.info "sendmail-php url=${HTTP_HOST}${REQUEST_URI}, client=${REMOTE_ADDR}, filename=${SCRIPT_FILENAME}, uid=${UID}, user=$(whoami), args=$*"
/usr/lib/sendmail -t -i $*
```

PHP will have to set the needed environment variables before the sendmail wrapper gets called. Create a `/home/httpd/htdocs/put_environment_variables.php` for that.

```php
<?php

ob_start();
$vars = array("SCRIPT_FILENAME", "HTTP_HOST", "REMOTE_ADDR", "REQUEST_URI");
foreach ($vars as $var) {
    putenv($var . "=" . $_SERVER[$var]);
}

?>
```

Finally, tell PHP to use those scripts by configuring `php.ini`.

```php
sendmail_path = /usr/local/bin/phpsendmail
auto_prepend_file = /home/httpd/htdocs/put_environment_variables.php
```


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


## Crontab examples

This is how our crontabs look like

```bash
# Web server crontab

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/spam-gear
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

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/spam-gear
0 * * * * postfix-spam-scan -m 90 -d 10,10 -n auth.ourdomain.org | emergency-mail 3000
```
