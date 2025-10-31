#!/bin/bash

if [ $# -ne 2 ]; then
 echo "1st parameter is ENV, 2nd parameter is  % usage"
else


 ALERT=$2 # alert level 
 MAILLOG=/tmp/mail.log

>$MAILLOG

 df -H | grep -vE '^Filesystem|tmpfs|cdrom' |  cut -d" " -f2- |awk '{ print $4 " " $5 }' | while read -r output;
 do
   if [ ! -z "$output" ] ; then
     usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1 )
     partition=$(echo "$output" | awk '{ print $2 }' )
   if [ $usep -ge $ALERT ]; then
     echo " \"$partition is ($usep%)\" on $1 $(hostname) " >>$MAILLOG
   fi
  fi
 done

 if [ $(wc -l <$MAILLOG ) -ne 0 ]; then
   mailx -s "Attn! CWA $1 filesystem space alert on $(hostname) " SLACK_ALERT_URL < $MAILLOG
 fi
 rm $MAILLOG
fi