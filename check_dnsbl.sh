#!/bin/bash

blacklists="access.redhawk.org
    b.barracudacentral.org
    bl.shlink.org
    bl.spamcannibal.org
    bl.spamcop.net
    bl.tiopan.com
    blackholes.wirehub.net
    blacklist.sci.kun.nl
    block.dnsbl.sorbs.net
    blocked.hilli.dk
    bogons.cymru.com
    cart00ney.surriel.com
    cbl.abuseat.org
    cblless.anti-spam.org.cn
    dev.null.dk
    dialup.blacklist.jippg.org
    dialups.mail-abuse.org
    dialups.visi.com
    dnsbl.abuse.ch
    dnsbl.anticaptcha.net
    dnsbl.antispam.or.id
    dnsbl.dronebl.org
    dnsbl.justspam.org
    dnsbl.kempt.net
    dnsbl.sorbs.net
    dnsbl.tornevall.org
    dnsbl-1.uceprotect.net
    duinv.aupads.org
    dnsbl-2.uceprotect.net
    dnsbl-3.uceprotect.net
    dul.dnsbl.sorbs.net
    dul.ru
    escalations.dnsbl.sorbs.net
    hil.habeas.com
    black.junkemailfilter.com
    http.dnsbl.sorbs.net
    intruders.docs.uu.se
    ips.backscatterer.org
    korea.services.net
    l2.apews.org
    mail-abuse.blacklist.jippg.org
    misc.dnsbl.sorbs.net
    msgid.bl.gweep.ca
    new.dnsbl.sorbs.net
    no-more-funn.moensted.dk
    old.dnsbl.sorbs.net
    opm.tornevall.org
    pbl.spamhaus.org
    proxy.bl.gweep.ca
    psbl.surriel.com
    pss.spambusters.org.ar
    rbl.schulte.org
    rbl.snark.net
    recent.dnsbl.sorbs.net
    relays.bl.gweep.ca
    relays.bl.kundenserver.de
    relays.mail-abuse.org
    relays.nether.net
    rsbl.aupads.org
    sbl.spamhaus.org
    smtp.dnsbl.sorbs.net
    socks.dnsbl.sorbs.net
    spam.dnsbl.sorbs.net
    spam.olsentech.net
    spamguard.leadmon.net
    spamsources.fabel.dk
    tor.ahbl.org
    tor.dnsbl.sectoor.de
    ubl.unsubscore.com
    web.dnsbl.sorbs.net
    xbl.spamhaus.org
    zen.spamhaus.org
    zombie.dnsbl.sorbs.net
    dnsbl.inps.de
    dyn.shlink.org
    rbl.megarbl.net
    bl.mailspike.net"



IPR=$(echo "$1"|awk -F'.' {'print $4"."$3"."$2"."$1'})
j=0;k=0;
reason=""
black=""
for blacklist in $blacklists; do 
    if [[ $(dig "$IPR"".""$blacklist"|grep ';; ANSWER SECTION') ]]; then
        actreason=$(dig "$IPR"".""$blacklist" TXT|grep -A2 ';; ANSWER SECTION:'|grep 'TXT'|cut -d'"' -f2)
        if [[ "$actreason" == "" ]]; then
            actreason='Unknown reason'
        fi
        ((j++))
        if [[ $(echo "$actreason"|wc -m) -gt $(echo "$reason"|wc -m) ]]; then
            reason=$actreason;
        fi
        black="${black}""$blacklist;"
    fi
    ((k++))
done


if [[ $j -gt 1 ]]; then
    echo "CRITICAL - IP ""$1"" in $j/$k blacklists. Reason: ""$reason"". |In: $black"
    exit 2
elif [[ $j -gt 0 ]]; then
    echo "WARNING - IP ""$1"" in $j/$k blacklists. Reason: ""$reason"". |In: $black"
    exit 1
else
    echo "OK - IP ""$1"" Not in any $k blacklists"
    exit 0;
fi

