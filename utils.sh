#!/bin/bash

. $(dirname "$0")/config.sh


function send_emergency_mail () {
    python -c "$(cat <<- EOF
		import smtplib
		import email.utils
		from email.mime.text import MIMEText
		
		MAIL_FROM = '$EMERGENCY_MAIL_FROM'
		SUBJECT = 'EMERGENCY MAIL ABUSE REPORT - $SERVER_NAME'
		MESSAGE = $2
		
		for SMTP_SERVER, MAIL_TO in $EMERGENCY_MAIL_TO:
		    msg = MIMEText(MESSAGE)
		    msg['To'] = ', '.join(MAIL_TO)
		    msg['From'] = MAIL_FROM
		    msg['Subject'] = SUBJECT
		    server = smtplib.SMTP(SMTP_SERVER, 25)
		    try:
		        server.ehlo()
		        server.starttls()
		        server.ehlo()
		        server.sendmail(MAIL_FROM, MAIL_TO, msg.as_string())
		    except Exception as detail:
		        print 'Error sending:', detail
		        continue
		    finally:
		        server.quit()
		
		EOF
    )"
