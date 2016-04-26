# Tips

* Prevent CGI execution on upload directories
```
<DirectoryMatch ".*upload.*">
    Options -ExecCGI
    # PHP-FPM
    <Files *.php>
        deny from all
    </Files>
</DirectoryMatch>
```
* Disable security sensitive PHP functions
```
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,show_source,pcntl_exec,proc_close,proc_get_status,proc_nice,proc_terminate,ini_alter,virtual,openlog,dl,fsockopen,pfsockopen,stream_socket_client,getmxrr
```
* Monitor for unusual activity. Perl scripts running on a web hosting environment are usually a security breach symptom.
```
*/5  * * * *  ps aux|grep ' perl '|grep -v ' grep '
```
* Don't use your primary mail server for sending web-users mail
* Use [fail2ban](http://www.fail2ban.org)
* Use Apache [modsecurity](https://www.modsecurity.org)

