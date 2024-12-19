#!/bin/ksh

if [ $# -ne 1 ]; then
 echo "1st parameter is ENV"
fi

# fixed variables
chown -R oracle:dba /home/oracle/scripts

LOCATE=/home/oracle/scripts
ORACLE_SID=$1; export ORACLE_SID
ORACLE_HOME=/oracle/software/product/10.2.0; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH

cd $LOCATE

sqlplus -s /nolog <<eosql >rundatafix.log
conn warehouse/whouse_prod
@maat_05365_ware_db_changes.sql
exit
eosql

mailx -s "MI $1 (EDW005) datafix 3079 \`date\`" SLACK_ALERT_URL < rundatafix.log
