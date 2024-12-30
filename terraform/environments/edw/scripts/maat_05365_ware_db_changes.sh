#!/bin/ksh

if [ $# -ne 1 ]; then
 echo "1st parameter is ENV"
else
# fixed variables
chown -R oracle:dba /home/oracle/scripts

LOCATE=/home/oracle/scripts
ORACLE_SID=EDW;export ORACLE_SID
ORACLE_HOME=/oracle/software/product/10.2.0; export ORACLE_HOME
PATH=$PATH:$ORACLE_HOME/bin; export PATH

echo 'Script run on $(date)' >> maat_05365_ware_db_changes.log  # Append run time to log

cd $LOCATE

sqlplus -s /nolog <<eosql >maat_05365_ware_db_changes.log
conn warehouse/password
@maat_05365_ware_db_changes.sql
exit
eosql

mailx -s "MI $1 (EDW005) datafix 3079 \`date\`" SLACK_ALERT_URL < maat_05365_ware_db_changes.log
fi