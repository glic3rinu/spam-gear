# Log analysis tools

## [postfix-spam-check](postfix-spam-check)


Scans Postfix logs `/var/log/mail.log` looking for SASL authenticated users that make
more than `MAX_CONNECTIONS` per time `PERIOD`. Covering the typical attacks on a mail server setup.

It can disable users based on the number of connections from different and unknown networks. Which is a very distinguishable pattern of mails sent from a botnet.

#### Usage
    postfix-spam-check [OPTIONS]


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
    postfix-spam-check
    postfix-spam-check -p 30minutes -m 60
    postfix-spam-check -d 10,10



## [exim-spam-check](exim-spam-check)


Scans Exim4 logs under `/var/log/exim/mainlog` looking for *local users* and *SMTP connections*
that exceed `MAX_CONNECTIONS` during the last `SECONDS`. Covering the typical attacks on a shared hositing web server setup.

#### Usage
    exim-spam-check [SECONDS] [MAX_CONNECTIONS]

#### Examples
    exim-spam-check 3600
    exim-spam-check 3600 60



## [roundcube-spam-scheck](roundcube-spam-scheck)


TODO


## [imp-spam-scheck](imp-spam-scheck)

TODO



## [php-spam-check](php-spam-check)


With PHP &ge; 5.3 there is this feature that you can enable for logging emails sent via PHP. This can be done 
by setting `mail.log = /var/log/phpmail.log` on `php.ini`. Don't forget to rotate this new log file.


This script inspects `/var/log/phpmail.log` and returns the PHP scripts that exceed `MAX_DAILY_MAILS`.

Usually you want to run this script combined with `php-shell-scan`.

#### Usage
    php-spam-check [MAX_DAILY_MAILS]

#### Examples
    php-spam-check
    php-spam-check 100
    php-spam-check 500 && php-spam-legacy 10 10



## [php-legacy-spam-check](php-legacy-spam-check)

This script is for legacy versions of PHP (&lt; 5.3), it inspects `/var/log/mail.log` and returns PHP scripts that exceed `MAX_MAILS` over the last number of `MINUTES`.

Usually you want to run this script combined with `php-shell-check`.


#### Usage
    php-legacy-spam-check [MINUTES] [MAX_MAILS]

#### Examples
    php-legacy-spam-check
    php-legacy-spam-check 10 30
    php-legacy-spam-check 10 10 && php-spam 500


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

