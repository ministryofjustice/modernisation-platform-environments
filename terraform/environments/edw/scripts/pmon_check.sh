#!/bin/ksh

# fixed variables
LOCATE=$HOME/scripts
export curdate=$(date)
logz=$LOCATE/logs/pmon_status_alert.log

cd $LOCATE

echo "PMON status as of " $curdate >$logz
ps -ef | grep -v check | grep -v grep | grep -c pmon >/dev/null && echo "PMON process is running" >>$logz || echo "PMON process is DOWN" >>$logz