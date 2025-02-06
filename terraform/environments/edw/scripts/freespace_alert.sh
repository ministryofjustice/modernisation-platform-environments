#!/bin/ksh

if [ $# -ne 1 ]; then
 echo "1st parameter is ENV"
else
# fixed variables
LOCATE=$HOME/scripts
ORACLE_SID=EDW;export ORACLE_SID
ORACLE_HOME=/oracle/software/product/10.2.0;export ORACLE_HOME
PATH=$PATH:$ORACLE_HOME/bin
export curdate=$(date)
ORAENV_ASK="NO";export ORAENV_ASK
#. oraenv

cd $LOCATE

sqlplus -s /nolog <<eosql >logs/freespace_alert.log
conn / as sysdba
@freespace_alert.sql
exit
eosql
if grep "no rows" logs/freespace_alert.log
then 
  echo "all good"
else
  mailx -s "EDW $1 freespace at `date`" SLACK_ALERT_URL -- < logs/freespace_alert.log
fi
fi