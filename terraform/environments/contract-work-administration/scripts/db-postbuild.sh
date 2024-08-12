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

# echo "Postbuild - Setting up ntp"
# /bin/cp -p -f /etc/ntp.conf /etc/ntp.conf.bck
# sed -i "s/server 0.rhel.pool.ntp.org/server 169.254.169.123/g" /etc/ntp.conf
# sed -i "s/server 1.rhel.pool.ntp.org/#server 1.rhel.pool.ntp.org/g" /etc/ntp.conf
# sed -i "s/server 2.rhel.pool.ntp.org/#server 2.rhel.pool.ntp.org/g" /etc/ntp.conf

# service ntpd start
# chkconfig ntpd on

## Install chrony to ensure database time is accurate, instead of ntpd
echo "Postbuild - Installing chrony"
yum -y install chrony
cat <<EOT > /etc/chrony.conf
server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Enable kernel RTC synchronization.
rtcsync

# In first three updates step the system clock instead of slew
# if the adjustment is larger than 1.0 seconds.
makestep 1.0 3

logdir /var/log/chrony

# Select which information is logged
log measurements statistics tracking
EOT

service chronyd start
chkconfig chronyd on



echo "Postbuild - Setting up oracle directories"
mkdir -p /efs/cwa_rman
chmod 777 /efs/cwa_rman
mkdir -p /home/oracle/backup_logs
chown oracle:oinstall /home/oracle/backup_logs