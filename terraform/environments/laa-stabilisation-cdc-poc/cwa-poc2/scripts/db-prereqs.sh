echo "Prereq - Installing tools"
setenforce Permissive
# yum -y install sysstat sharutils 
# yum -y install postfix

# unzip /home/ec2-user/awscliv2.zip
# ./aws/install

groupadd dba -g 54322
groupadd oinstall -g 54321

echo "Prereq - Setting up users"
useradd -m applmgr -u 54322
usermod -g oinstall -G dba applmgr
mkdir /home/applmgr/.ssh
# echo "${pApplmgrKey}" >> /home/applmgr/.ssh/authorized_keys
# chown -R applmgr:applmgr /home/applmgr/.ssh

useradd -m oracle -g oinstall -G dba -u 54321
mkdir /home/oracle/.ssh
# echo "${pOracleKey}" >> /home/oracle/.ssh/authorized_keys
# chown -R oracle:dba /home/oracle/.ssh

# SLACK_ALERT_ADDRESS=${pSlackAlertsChannelEmail}
# export SLACK_ALERT_ADDRESS
mkdir -p /repo
chown -R oracle:oinstall /home/oracle

mkdir -p /home/oracle/scripts/log
chown -R oracle:oinstall /home/oracle/scripts/log