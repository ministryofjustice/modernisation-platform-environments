#!/bin/bash

chown -R oracle:dba /home/oracle/scripts
ORACLE_SID=EDW;export ORACLE_SID
ORACLE_HOME=/oracle/software/product/10.2.0
ORACLE_BASE=/oracle/software/product/; export ORACLE_BASE
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib; export LD_LIBRARY_PATH
PATH=$ORACLE_HOME/bin:$PATH;export PATH
TO_DATE="20`date +%y%m%d`"; export TO_DATE

echo =======
echo Extract Alert log location
echo =======
export VAL_DUMP=$(${ORACLE_HOME}/bin/sqlplus -S /nolog <<EOF
conn /as sysdba
set pages 0 feedback off;
prompt
SELECT value from v\$parameter where NAME='background_dump_dest';
exit;
EOF
)
export LOCATION=`echo ${VAL_DUMP} | perl -lpe'$_ = reverse' |awk '{print $1}'|perl -lpe'$_ = reverse'`
export ALERTDB=${LOCATION}/alert_$ORACLE_SID.log
export ELOG=$( echo ${ALERTDB} | sed s/cdump/trace/)

echo =======
echo Compress current
echo =======

if [ -e "$ELOG" ] ; then
mv ${ELOG} ${ELOG}_${TO_DATE};
gzip ${ELOG}_${TO_DATE};
> ${ELOG}
else
echo not found
fi

exit