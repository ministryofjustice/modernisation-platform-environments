#!/bin/bash

##### USERDATA #####

####install missing package and hostname change
yum -y install libXp.i386
yum -y install sshpass
echo "HOSTNAME="${edw_app_name}"."${edw_dns_extension}"" >> /etc/sysconfig/network

#### configure aws timesync (external ntp source)
AwsTimeSync(){
    local RHEL=$1
    local SOURCE=169.254.169.123

    NtpD(){
        local CONF=/etc/ntp.conf
        sed -i 's/server \S/#server \S/g' $CONF && \
        sed -i "20i\server $SOURCE prefer iburst" $CONF
        /etc/init.d/ntpd status >/dev/null 2>&1 \
            && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
        ntpq -p
    }
    ChronyD(){
        local CONF=/etc/chrony.conf
        sed -i 's/server \S/#server \S/g' $CONF && \
        sed -i "7i\server $SOURCE prefer iburst" $CONF
        systemctl status chronyd >/dev/null 2>&1 \
            && systemctl restart chronyd || systemctl start chronyd
        chronyc sources
    }
    case $RHEL in
        5)
            NtpD
            ;;
        7)
            ChronyD
            ;;
    esac
}
AwsTimeSync $(cat /etc/redhat-release | cut -d. -f1 | awk '{print $NF}')

####Install AWS cli
mkdir -p /opt/aws/bin
cd /root
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-latest.tar.gz
mkdir -p /run/cfn-init # Path to store cfn-init scripts

####configure cfn-init variables
export ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
export LOGS="${edw_app_name}-EC2"
export APPNAME="${edw_app_name}"
export ENV="${edw_environment}"
export BACKUPBUCKET="${edw_s3_backup_bucket}"
export ROLE="${edw_ec2_role}"
export SECRET=`/usr/local/bin/aws --region ${edw_region} secretsmanager get-secret-value --secret-id $${terraform output -raw edw_db_secret} --query SecretString --output text`
export host="$ip4 $APPNAME-$ENV $APPNAME.${edw_dns_extension}"
export host2="${edw_cis_ip} cis.aws.${edw_environment}.legalservices.gov.uk"
export host3="${edw_eric_ip} eric.aws.${edw_environment}.legalservices.gov.uk"
export host3="${edw_ccms_ip} ccms.aws.${edw_environment}.legalservices.gov.uk"
echo $host >>/etc/hosts
echo $host2 >>/etc/hosts
echo $host3 >>/etc/hosts
mkdir -p /home/oracle/scripts

##### METADATA #####


#### Setup_log_files

echo "---creating /etc/awslogs/awscli.conf"
mkdir -p /etc/awslogs
cat > /etc/awslogs/awscli.conf <<-EOF
[plugins]
cwlogs = cwlogs
[default]
region = ${edw_region}
EOF

echo "---creating /tmp/cwlogs/logstreams.conf"
mkdir -p /tmp/cwlogs

cat > /tmp/cwlogs/logstreams.conf <<-EOF
[general]
state_file = /var/awslogs/agent-state

[cfn-init]
file = /var/log/cfn-init.log
log_group_name = ${edw_app_name}-CfnInit
log_stream_name = ${edw_instance_id}

[oracle_alert_log_errors]
file = /oracle/software/product/10.2.0/admin/${edw_app_name}/bdump/alert_${edw_app_name}.log
log_group_name = ${edw_app_name}-OracleAlerts
log_stream_name = ${edw_instance_id}

[rman_backup_log_errors]
file = /home/oracle/backup_logs/*_RMAN_disk_*.log
log_group_name = ${edw_app_name}-RMan
log_stream_name = ${edw_instance_id}

[rman_arch_backup_log_errors]
file = /home/oracle/backup_logs/*_RMAN_disk_ARCH_*.log
log_group_name = ${edw_app_name}-RManArch
log_stream_name = ${edw_instance_id}

# adding logs for space report
[db_tablespace_space_alerts]
file = /home/oracle/scripts/logs/freespace_alert.log
log_group_name = ${edw_app_name}-TBSFreespace
log_stream_name = ${edw_instance_id}

# adding logs for pmon monitor
[db_PMON_status_alerts]
file = /home/oracle/scripts/logs/pmon_status_alert.log
log_group_name = ${edw_app_name}-PMONstatus
log_stream_name = ${edw_instance_id}

# adding logs for CDC monitor
[db_CDC_status_alerts]
file = /home/oracle/scripts/logs/cdc_check.log
log_group_name = ${edw_app_name}-CDCstatus
log_stream_name = ${edw_instance_id}

EOF

# Set permissions for created files
chmod 700 /etc/awslogs/awscli.conf
chmod 700 /tmp/cwlogs/logstreams.conf
chown root:root /etc/awslogs/awscli.conf /tmp/cwlogs/logstreams.conf

# Execute the command to install log files
/run/cfn-init/install_log_files


#### Install_aws_logging

# Error handeling
error_exit()
{
echo "$1" 1>&2
exit 1
}

#Install AWS logs
echo "---Install AWS logging"
curl -O https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py
/usr/local/bin/python2.7 awslogs-agent-setup.py --no-proxy=NO_PROXY -n -r eu-west-2 -c /tmp/cwlogs/logstreams.conf || exit 2


#### setup_file_systems

# Create Oracle DBF file file system
mkfs.ext4 /dev/xvdf
mkdir -p /oracle/dbf
echo "/dev/xvdf /oracle/dbf ext4 defaults 0 0" >> /etc/fstab

# Create stage file system
mkfs.ext4 /dev/xvdg
mkdir -p /stage
echo "/dev/xvdg /stage ext4 defaults 0 0" >> /etc/fstab

# Create archive file system
mkfs.ext4 /dev/xvdh
mkdir -p /oracle/ar
echo "/dev/xvdh /oracle/ar ext4 defaults 0 0" >> /etc/fstab

#Create oracle_home
mkfs.ext4 /dev/xvdi
mkdir -p /oracle/software
echo "/dev/xvdi /oracle/software ext4 defaults 0 0" >> /etc/fstab

#Create temp_undo
mkfs.ext4 /dev/xvdj
mkdir -p /oracle/temp_undo
echo "/dev/xvdj /oracle/temp_undo ext4 defaults 0 0" >> /etc/fstab

# Mount all file systems in fstab
mount -a
chmod 777 /stage


#### setup_oracle_db_software

# Install wget / unzip
yum install -y unzip

groupadd dba
groupadd oinstall
useradd -d /home/oracle -g dba oracle

#setup oracle user access
cp -fr /home/ec2-user/.ssh /home/oracle/
chown -R oracle:dba /home/oracle/.ssh

# Unzip installers
mkdir -p /stage/databases
mkdir -p /stage/patches/1020
unzip /repo/databases/10.2/installers/B24792-01_1of5.zip -d /stage/databases
unzip /repo/databases/10.2/installers/B24792-01_2of5.zip -d /stage/databases
unzip /repo/databases/10.2/installers/B24792-01_3of5.zip -d /stage/databases
unzip /repo/databases/10.2/installers/B24792-01_4of5.zip -d /stage/databases
unzip /repo/databases/10.2/installers/B24792-01_5of5.zip -d /stage/databases
unzip /repo/databases/10.2/patches/db-patchset10204/p6810189_10204_Linux-x86-64.zip -d /stage/patches/10204

# Create directories and set ownership
mkdir -p /oracle/software/oraInventory
mkdir -p /oracle/software/product
mkdir -p /oracle/software/product/10.2.0
mkdir -p /oracle/software/product/10.2.0_owb
chown -R oracle:dba /oracle

# Create swap space
dd if=/dev/zero of=/swapfile bs=1024M count=9
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Run Oracle installer
cp -f /repo/databases/10.2/templates/db-install-10g.rsp /run/cfn-init/db-install-10g.rsp
chmod 777 /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_inventory_location }}/"\/oracle\/software\/oraInventory"/g' /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_oracle_home }}/"\/oracle\/software\/product\/10.2.0"/g'     /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_oracle_base }}/"\/oracle\/software\/product"/g'             /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_edition }}/"EE"/g'                                          /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_os_group }}/"dba"  /g'                                      /run/cfn-init/db-install-10g.rsp
sed -i 's/{{ oracle_database_oracle_home_name }}/"db_home"/g'                            /run/cfn-init/db-install-10g.rsp


# Run installer and post install
export ORA_DISABLED_CVU_CHECKS=CHECK_RUN_LEVEL
su oracle -c "/stage/databases/database/runInstaller -silent -waitforcompletion -ignoreSysPrereqs -ignorePrereq -responseFile /run/cfn-init/db-install-10g.rsp"

/oracle/software/oraInventory/orainstRoot.sh -silent
/oracle/software/product/10.2.0/root.sh -silent

# Update oracle login script
echo "export ORACLE_SID=EDW" >> /home/oracle/.bash_profile
echo "export ORACLE_HOME=/oracle/software/product/10.2.0" >> /home/oracle/.bash_profile
echo "export PATH=\$ORACLE_HOME/bin:\$PATH"           >> /home/oracle/.bash_profile

# patch the database to 10.2.0.4
cp -f /repo/databases/10.2/templates/patchset.rsp /home/oracle/patchset.rsp
chown oracle:dba /home/oracle/patchset.rsp
chmod 777 /home/oracle/patchset.rsp

su oracle -c "/stage/patches/10204/Disk1/runInstaller -silent -responseFile /home/oracle/patchset.rsp"
/oracle/software/product/10.2.0/root.sh -silent

#### create_blank_database

# Create a blank database
cp  -f /repo/databases/10.2/templates/edw_warehouse.dbt /run/cfn-init/edw_warehouse.dbt
chown oracle:dba /run/cfn-init/edw_warehouse.dbt
chmod 777 /run/cfn-init/edw_warehouse.dbt

su oracle -l -c "dbca -silent -createDatabase -templateName /run/cfn-init/edw_warehouse.dbt -gdbname $APPNAME -sid $APPNAME -responseFile NO_VALUE -characterSet WE8ISO8859P1 -sysPassword $SECRET -systemPassword $SECRET -databaseType DATA_WAREHOUSING  -datafileDestination "/oracle/dbf/" -MEMORYPERCENTAGE 70"

# create listener
cp -f /repo/databases/10.2/templates/netca.rsp /run/cfn-init/netca.rsp
chmod 777 /run/cfn-init/netca.rsp
su oracle -l -c "netca /silent /responseFile /run/cfn-init/netca.rsp"
su oracle -l -c "lsnrctl start"

mkdir -p /var/opt/oracle
chown oracle:dba /var/opt/oracle
cp /repo/edwcreate/passwds.sql /var/opt/oracle
cp -r /repo/edwcreate /home/oracle
chown -R oracle:dba /home/oracle/edwcreate
chmod -R 777 /home/oracle/edwcreate
chown oracle:dba /var/opt/oracle/passwds.sql
chmod 777 /var/opt/oracle/passwds.sql
su oracle -l -c "cp /home/oracle/edwcreate/tnsnames.ora /oracle/software/product/10.2.0/network/admin"
sed -i "s/tst/${edw_environment}/g" /oracle/software/product/10.2.0/network/admin/tnsnames.ora
sed -i "s/EDW_SYS=welc0me/EDW_SYS=$SECRET/g" /var/opt/oracle/passwds.sql
sed -i "s/EDW_SYSTEM=sysedw99/EDW_SYSTEM=$SECRET/g" /var/opt/oracle/passwds.sql

chown -R oracle:dba /home/oracle/scripts/
chmod -R 700 /home/oracle/scripts/
chown oracle:dba /home/oracle
chmod -R 777 /home/oracle

#### Setup_owb

# Create directories for OWB setup
mkdir -p /stage/owb/owb101
mkdir -p /stage/owb/owb104
mkdir -p /stage/owb/owb105

# Unzip OWB software packages
unzip /repo/Software/OWB10/B30394-01_1of2.zip -d /stage/owb/owb101
unzip /repo/Software/OWB10/B30394-01_2of2.zip -d /stage/owb/owb101
unzip /repo/Software/OWB10/p7005587_10204_Linux-x86-64.zip -d /stage/owb/owb104
unzip /repo/Software/OWB10/p8515097_10205_Linux-x86-64.zip -d /stage/owb/owb105

# Copy response files to staging directory
cp -f /repo/Software/OWB10/*.rsp /stage/owb/

# Set permissions for staging directory
chmod -R 777 /stage/owb/

# Install OWB components
su oracle -l -c "/stage/owb/owb101/Disk1/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -waitforcompletion -responseFile /stage/owb/owb.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

su oracle -l -c "/oracle/software/product/10.2.0/oui/bin/runInstaller -silent -waitforcompletion -responseFile /stage/owb/owb104.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

su oracle -l -c "/oracle/software/product/10.2.0/oui/bin/runInstaller -silent -waitforcompletion -responseFile /stage/owb/owb105.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

# Unzip additional files and configure environment
unzip /repo/edwcreate/refresh.zip -d /stage
unzip /repo/edwcreate/templates.zip -d /stage
echo "export OMB_path=/oracle/software/product/10.2.0_owb/owb/bin/unix" >> /home/oracle/.bash_profile

