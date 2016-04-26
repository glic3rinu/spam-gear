# Spam-gear

Anti-spam artillery for your multi-user web and mail servers.

This project consists of a handful of tools that, once combined, provide a good enough solution to two unsolvable problems.

1. Spammers sending spam through compromised PHP web applications on shared hosting environments
2. Spammers sending spam using stolen SMTP credentials


## Installation
```bash
cd /usr/local/share/
git clone https://github.com/glic3rinu/spam-gear.git
```


## Contents

* [Log analysis tools](logs) - Identify and stop spammers by looking at log files
    * [postfix-spam-check](logs/postfix-spam-check)
    * [exim-spam-check](logs/exim-spam-check)
    * [roundcube-spam-check](logs/roundcube-spam-check)
    * [imp-spam-check](logs/imp-spam-check)
    * [php-spam-check](logs/php-legacy-check)
    * [php-legacy-spam-check](logs/php-legacy-spam-check)
* [Filesystem scan tools](scans) - Detect and remove malicious code from your system
    * [full-scan](scans/full-scan) - Wrapper for clamd-client and php-shell-detector
    * [clamd-client](scans/clamd-client) - Python client for [Clamd](http://www.clamav.net)
    * [php-shell-detector](scans/php-shell-detector) - Rewrite of [Shell-Detector](https://github.com/emposha/Shell-Detector)
* [Utils](utils) - Miscellaneous directory
    * [emergency-mail](utils/emergency-mail) - SMTP client for sending emails outside
    * [check_dnsbl.sh](utils/check_dnsbl.sh) - Nagios black list checker
    * [runav.sh](utils/runav.sh) - full-scan wrapper for modsecurity
* [Tips](TIPS.md) - Common tips and best practices for reducing spam incidents


## Tips

### Web

1. Prevent CGI execution on upload directories
    ```
    <DirectoryMatch ".*upload.*/.*">
        Options -ExecCGI
        <Files *.php>
            deny from all
        </Files>
    </DirectoryMatch>
    # PHP-FPM
    <LocationMatch ".*upload.*/.*.php">
            deny from all
    </LocationMatch>
    ```

2. Disable security sensitive PHP functions
    ```
    disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,show_source,pcntl_exec,proc_close,proc_get_status,proc_nice,proc_terminate,ini_alter,virtual,openlog,dl,fsockopen,pfsockopen,stream_socket_client,getmxrr
    ```

3. Monitor for unusual activity. Perl scripts running on a web hosting environment are usually a security breach symptom.
    ```
    */5  * * * *  ps aux|grep ' perl '|grep -v ' grep '
    ```

4. Don't use your primary mail server for sending webusers mail

5. Use [fail2ban](http://www.fail2ban.org), and ban failed attemps at `login.php` endpoints
    ```
    # /etc/fail2ban/filter.d/php-login.conf
    [Definition]
    failregex = ^<HOST> .* "POST .*login.php
    ignoreregex = 
    
    # /etc/fail2ban/jail.local
    [php-login]
    enabled = true
    filter = php-login
    action = iptables-multiport[name=NoAuthFailures, port="http,https"]
    logpath = /home/*/logs/apache/access_*.log
    bantime = 1200
    maxretry = 8
    ```

6. Use Apache [ModSecurity](https://www.modsecurity.org)

7. Inspect uploaded files with ModSecurity and spam-gear
    ```
    # modsecurity.conf
    SecRule FILES_TMPNAMES "@inspectFile /usr/local/share/spam-gear/utils/runav.sh" \
        "id:159,phase:2,t:none,log,deny,msg:'Malicious Code Detected, access denied'"
    ```

7. Run CGIs with Apache [SuEXEC](https://httpd.apache.org/docs/current/suexec.html)

8. Scan for recently upload malicious files every day and the entire home filesystem once a week.
    ```
    30   4 * * 0-5 find /home/ -type f -mtime -2 -iname "*php" | full-scan -q --notify-user -c /usr/local/share/spam-gear/conf/alerta_pangea.email
    30   1 * * 6   find /home/ -type f -size -5M | full-scan --quarantine --notify-user -c /usr/local/share/spam-gear/conf/alerta_pangea.email
    ```

9. Real-time scanning of scripts that send mail
    ```
    */10 * * * *   { php-sendmail2relay-spam-check 10 10 && php-spam-check 500; } | full-scan -q --notify-user -c /usr/local/share/spam-gear/conf/alerta_pangea.email
    ```

11. Periodically update php-shell-detector and spam-gear fingerprints.txt and backdoors.re
    ```
    0    0 * * *   php-shell-detector --update
    0    0 * * *   wget https://github.com/glic3rinu/spam-gear/raw/master/scans/fingerprints.txt -O /usr/local/share/spam-gear/scans/fingerprints.txt
    0    0 * * *   wget https://github.com/glic3rinu/spam-gear/raw/master/scans/backdoors.re -O /usr/local/share/spam-gear/scans/backdoors.re
    ```

10. Periodically monitor logfiles for users that send large ammount of mail, using local SMTP, roundcube or Horde IMP. Tunne thresholds for automatically disable users based on the number of IPs, networks and emails they send.
    ```
    */20 * * * *   postfix-spam-check -p 1hour -m 90 -d 5,5 -w 77.246.181.201,10.0.0.21 | emergency-mail 3000
    */20 * * * *   exim-spam-check -p 1hour -m 90 | emergency-mail 2000
    */20 * * * *   roundcube-spam-check -p 1hour -m 60 -d 10,10 -l /home/pangea/logs/roundcube/sendmail | emergency-mail 3000
    */20 * * * *   imp-spam-check -p 1hour -m 60 -d 10,10 -l /home/pangea/logs/horde/horde3.log | emergency-mail 3000
    ```



### Mail

8. Periodically [check for DNSBL inclusion](utils/check_dnsbl.sh), using Nagios or a cronjob.

7. Monitor and analyse your spam patterns with [Baruwa](https://www.baruwa.org/), and create MailScanner rules accordingly.

11. Use Postfix [header checks](http://www.postfix.org/header_checks.5.html) to relay bad-reputation users to secondary mail servers
    ```
    /^Received:.*\(Authenticated sender: (baduser1|baduser2|baduser3)\)\s*by mail.pangea.org\b/
        FILTER relay:bad-mail.pangea.org
    ```

12. Check outgoing mail for spam

13. Develop custom MailScanner rules for phishing attacks
14. Use [Postfix check_recipient_access](http://www.postfix.org/postconf.5.html#check_recipient_access) to block known phishing return addresses
    ```
    # recipient_access
    helpdeskunit590@mail2world.com REJECT Don't reply to spammers
    carecenter123@gmail.com REJECT Don't reply to spammers
    ```


<!--TODO full-scan construct full paths from clamd-client -->
<!--TODO regex support for fingerprints -->
