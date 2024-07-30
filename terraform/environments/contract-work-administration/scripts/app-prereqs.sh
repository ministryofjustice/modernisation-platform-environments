##### Application server pre-build user data

echo "Prereq - Installing tools"
setenforce Permissive
# unzip /home/ec2-user/awscliv2.zip
# ./aws/install

mkdir /efs/CWA
chmod 777 /efs/CWA

echo "Prereq - Setting up users"
useradd -m applmgr -u 54322
usermod -g oinstall -G dba applmgr
mkdir /home/applmgr/.ssh
# echo "${pApplmgrKey}" >> /home/applmgr/.ssh/authorized_keys
# chown -R applmgr:applmgr /home/applmgr/.ssh

useradd -m oracle -u 54321
usermod -g oinstall -G dba oracle
mkdir /home/oracle/.ssh
chown -R oracle:dba /home/oracle/.ssh
su -l applmgr -c "mkdir /efs/CWA/tmp;chmod 775 /efs/CWA/tmp"


mkdir -p /home/applmgr/scripts
chown -R applmgr:oinstall /home/applmgr/scripts