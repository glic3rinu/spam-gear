# Spam-gear

Anti-spam artillery for your multi-user web and mail servers.

Spam-gear scripts follow the UNIX design philosophy of combining small tools that do one thing, and do it well.

These scripts don't have dependencies other than standard UNIX commands, Bash and Python. With the only exception of php-shell-scan, that uses clamscan.

We run them under Debian, don't know about compatibility with other distros.


### Installation
```bash
cd /root
git clone https://github.com/glic3rinu/spam-gear.git
```

## [postfix-spam-scan](postfix-spam-scan)


Scans Postfix logs `/var/log/mail.log` looking for SASL authenticated users that make
more than `MAX_CONNECTIONS` per time `PERIOD`. Covering the typical attacks on a mail server setup.

#### Usage

    postfix-spam-scan [PERIOD] [MAX_CONNECTIONS]

#### Examples

    postfix-spam-scan
    postfix-spam-scan 1hour
    postfix-spam-scan 1hour 90

#### TODO

Full support for botnet detector based on number of different networks, unkowns and IP addresses.*


## [exim-spam-scan](exim-spam-scan)


Scans Exim4 logs under `/var/log/exim/mainlog` looking for *local users* and *SMTP connections*
that exceed `MAX_CONNECTIONS` during the last `SECONDS`. Covering the typical attacks on a shared hositing web server setup.

#### Usage

    postfix-spam-scan [SECONDS] [MAX_CONNECTIONS]

#### Examples

    exim-spam-scan 3600
    exim-spam-scan 3600 60


## [php-shell-scan](php-shell-scan)

This is anti-PHP Shells heavy weaponry. It combines custom regular expressions, Clamscan and [PHP-Shell-Dectector](http://www.shelldetector.com/) all within a single shot. Also It automatically disables the malicious files by moving them into a `QUARANTINE_DIR`.

A rewrite of the [Python version](https://github.com/emposha/Shell-Detector) of PHP-Shell-Dectector is included in this package ([php-shell-detector](php-shell-detector)). Motivated because the original implementation just crashed when testing it through our quarantine directory, the output was hard to parse, it had no support for inspecting specific files (only dirs). And guess what? it turned out to be x10 faster than the orifinal implementation ;).


#### Usage

    find . | php-shell-scan [QUARANTINE_DIR]

#### Examples

    find /home/ -iname "*php" | php-shell-scan


## [php-spam](php-spam)

With PHP &ge; 5.3 there is this feature that you can enable for logging emails sent via PHP. This can be done 
by setting `mail.log = /var/log/phpmail.log` on `php.ini`.


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
logger -p mail.info "sendmail-php site=${HTTP_HOST}, client=${REMOTE_ADDR}, filename=${SCRIPT_FILENAME}, pwd=${PWD}, uid=${UID}, user=$(whoami), args=$*"
/usr/lib/sendmail -t -i $*
```

PHP will have to set the needed environment variables before the sendmail wrapper gets called. Create a `/home/httpd/htdocs/put_environment_variables.php` for that.

```php
<?php
    ob_start();
    putenv("SCRIPT_FILENAME=" . $_SERVER['SCRIPT_FILENAME']);
    putenv("HTTP_HOST=" . $_SERVER['HTTP_HOST']);
    putenv("REMOTE_ADDR=" . $_SERVER['REMOTE_ADDR']);
?>
```

Finally, tell PHP to use those scripts by configuring `php.ini`.

```php
sendmail_path = /usr/local/bin/phpsendmail
auto_prepend_file = /home/httpd/htdocs/put_environment_variables.php
```



## [emergency-mail](emergency-mail)


Sometimes during spam attacks your local mail server queue is badly saturated with tons of spam, potentially creating large delays on mail delivery, including alerts sent by the awesome spam-gear scripts :).

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
0    * * * * exim-spam-scan 3600 60 | emergency-mail 2000
30   5 * * * find /home/pangea/ -mtime -2 -iname "*php" | php-shell-scan
*/10 * * * * { php-spam-legacy 10 10 && php-spam 500; } | php-shell-scan
```

```bash

# Mail server crontab

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/spam-gear
0 * * * * postfix-spam-scan 1hour 90 | emergency-mail 3000
```
