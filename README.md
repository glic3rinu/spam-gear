Spam-gear
=========

postfix-spam-scan
-----------------

Scans the postfix logs `/var/log/mail.log` looking for sasl authenticated users that make
more than `MAX_CONNECTIONS` per time `PERIOD`.

Tipical mail server setup.

USAGE

    postfix-spam-scan [PERIOD] [MAX_CONNECTIONS]

EXAMPLES

    postfix-spam-scan 1hour
    postfix-spam-scan 1hour 90
    0 * * * * postfix-spam-scan 1hour 90 | emergency-mail 3000


TODO: full support for botnet detector based on number of different networks, unkowns and IP addresses.


exim-spam-scan
--------------

Scans the postfix logs `/var/log/exim/mainlog` looking for local users and smtp connections
than exceed `MAX_CONNECTIONS` during the last `SECONDS`.

Tipical web server setup.

USAGE

    postfix-spam-scan [SECONDS] [MAX_CONNECTIONS]

EXAMPLES

    exim-spam-scan 3600
    exim-spam-scan 3600 60
    0 * * * * exim-spam-scan 3600 60 | emergency-mail 3000


php-shell-scan
--------------
Scans a list of files looking for common PHP Shell patterns. It disables the found scripts
moving them on the `QUARANTINE_DIR`.


USAGE

    php-shell-scan [QUARANTINE_DIR]

EXAMPLES

    find /home/ -iname "*php" | php-shell-scan
    30 5 * * * find /home/ -mtime -2 -iname "*php" | php-shell-scan


php-spam
--------

With PHP >= 5.3 there is this feature that you can enable to log emails sent with PHP. This feature can be enabled
by setting `mail.log = /var/log/phpmail.log` on the `php.ini`.


This script inspects `/var/log/phpmail.log` and returns scripts that exceed `MAX_DAILY_MAILS`.

Usually you want to run this script combined with `php-shell-scan` and `php-spam-legacy`.


USAGE

    php-spam [MAX_DAILY_MAILS]

EXAMPLES

    php-spam
    php-spam 100
    */10 * * * * { php-spam 500 && php-spam-legacy; } | php-shell-scan



php-spam-legacy
---------------

PHP <= 5.2 has no built-in support for logging scripts that send mail. However, you can still log the php scripts that send mail by 
creating a wrapper around sendmail.

First create a `/usr/local/bin/phpsendmail` file with the following content

    #!/bin/bash
    logger -p mail.info "sendmail-php site=${HTTP_HOST}, client=${REMOTE_ADDR}, filename=${SCRIPT_FILENAME}, pwd=${PWD}, uid=${UID}, user=$(whoami), args=$*"
    /usr/lib/sendmail -t -i $*


Then PHP will have to set all these environment variables before this script gets called. Create a `/home/httpd/htdocs/put_environment_variables.php` for that.

    <?php
        ob_start();
        putenv("SCRIPT_FILENAME=" . $_SERVER['SCRIPT_FILENAME']);
        putenv("HTTP_HOST=" . $_SERVER['HTTP_HOST']);
        putenv("REMOTE_ADDR=" . $_SERVER['REMOTE_ADDR']);
    ?>


Finally configure the `php.ini` to use those files:

    sendmail_path = /usr/local/bin/phpsendmail
    auto_prepend_file = /home/httpd/htdocs/put_environment_variables.php



`php-spam-legacy` inspects `/var/log/mail.log` and returns scripts that exceed `MAX_MAILS` over the last number of `MINUTES`.

Usually you want to run this script combined with `php-shell-scan` and `php-spam`.


USAGE

    php-spam-legacy [MINUTES] [MAX_MAILS]

EXAMPLES

    php-spam-legacy
    php-spam-legacy 10 30
    */10 * * * * { php-spam-legacy 10 10 && php-spam 500; } | php-shell-scan


emergency-mail
--------------

Some times during spam attacks your local mail server queue is badly saturated with tons of spam, potentially creatign delays on theses alerting messages.

This script opens an SMTP connection to a remote server and send the report through it. But, it only does so when a certain number of messages on the MAILQ is reached.

In order to use this script you should copy `emergency-settings.example` to `emergency-settings` and edit them according to your needs.

This script is particularly useful combined with `postfix-spam-scan` or `exim-spam-scan`.


