mkdir -p /CWA/share/xxlsc
chown oracle:oinstall /CWA/share/xxlsc
chmod 775 /CWA/share/xxlsc
cat <<EOT > /etc/exports
/CWA/share *(rw)
EOT

echo "Postbuild - Updating sysconfig"
sed -i '/LOCKD_TCPPORT/s/^#//g' /etc/sysconfig/nfs
sed -i '/LOCKD_UDPPORT/s/^#//g' /etc/sysconfig/nfs
sed -i '/MOUNTD_PORT/s/^#//g' /etc/sysconfig/nfs
sed -i '/STATD_PORT/s/^#//g' /etc/sysconfig/nfs


echo "Postbuild - Updating services (nfs, iptables)"
service nfslock stop
service nfs stop
service nfs start
service nfslock start

chkconfig nfs on
chkconfig nfslock on

service iptables stop
chkconfig iptables off

echo "Postbuild - Updating bash_profile"
cat <<EOT > /home/oracle/.bash_profile
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
           . ~/.bashrc
fi
export ORACLE_HOME=/CWA/oracle/product/10.2.0/db_1
export ORACLE_SID=CWA
PATH=$ORACLE_HOME/bin:$PATH:$HOME/bin
export PATH
. /CWA/oracle/product/10.2.0/db_1/CWA_cwa-db.env
alias sql='sqlplus / as sysdba'
alias alert='cd /CWA/oracle/product/10.2.0/db_1/admin/CWA_base/bdump'

alias scripts='cd /efs/stage/scripts'
EOT

# User specific environment and startup programs

echo "Postbuild - Setting alias"
# PATH=$PATH:$HOME/bin
# export PATH
# . /CWA/oracle/product/10.2.0/db_1/CWA_cwa-db.env
alias sql='sqlplus / as sysdba'
alias alert='cd /CWA/oracle/product/10.2.0/db_1/admin/CWA_base/bdump'
alias scripts='cd /efs/stage/scripts'

echo "Postbuild - Setting up ntp"
/bin/cp -p -f /etc/ntp.conf /etc/ntp.conf.bck
sed -i "s/server 0.rhel.pool.ntp.org/server 169.254.169.123/g" /etc/ntp.conf
sed -i "s/server 1.rhel.pool.ntp.org/#server 1.rhel.pool.ntp.org/g" /etc/ntp.conf
sed -i "s/server 2.rhel.pool.ntp.org/#server 2.rhel.pool.ntp.org/g" /etc/ntp.conf

service ntpd start
chkconfig ntpd on

echo "Postbuild - Setting up oracle directories"
/bin/cp -f /etc/cron.d/oracle_cron  /home/oracle/oraclecrontab.txt
chown oracle:dba /home/oracle/oraclecrontab.txt
chmod 744 /home/oracle/oraclecrontab.txt
su oracle -c "crontab /home/oracle/oraclecrontab.txt"
chown -R oracle:dba /home/oracle/scripts

mkdir -p /efs/cwa_rman
chmod 777 /efs/cwa_rman
mkdir -p /home/oracle/backup_logs
chown oracle:oinstall /home/oracle/backup_logs