# Filesystem scan utilities

## [full-scan](full-scan)

This is anti-PHP-shells heavy weaponry. It combines custom fingerprints and regular expressions, Clamscan and [PHP-Shell-Dectector](http://www.shelldetector.com/), all within one single shot. It can disable malicious files by moving them into a `QUARANTINE_DIR` and remove common PHP backdooring code as well as alert infected users via customized e-mails.

The three scanning methods run concurrently on separated processes an interconnected by pipes. This is very efficient, not only because they can run on different core, but also because taking advantage of the filesystem cache; a file is brought from disk to memory once, not 3 times ;)

A rewrite of the [Python version](https://github.com/emposha/Shell-Detector) of PHP-Shell-Dectector is included in this package ([php-shell-detector](php-shell-detector)). Motivated because the original implementation just crashed when tested through our PHP shells collection, the output was hard to parse and it had no support for inspecting specific files (only dirs). And guess what? it turned out to be x10 faster than the original implementation ;).

A Python client for clamd, [clamd-client](clamd-client), is also included. Mainly because having better control over the pipeline stream and also being able to submit jobs concurrently to the clamd daemon using a thread pool pattern.


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


## [clamd-client](clamd-client)

TODO

## [php-shell-detector](php-shell-detector)

TODO
