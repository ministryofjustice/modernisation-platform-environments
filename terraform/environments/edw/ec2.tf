locals {
  db_userdata = <<-EOF
#!/bin/bash

# Disable requiretty
sed -i 's/^\(Defaults\s*requiretty\)/#\1/' /etc/sudoers

# Redirect all output to a log file and enable debugging
exec > /var/log/userdata.log 2>&1
set -x

#### USERDATA ######

#### install missing package and hostname change
echo "---install missing package and hostname change"
sudo yum -y install libXp.i386
sudo yum -y install sshpass
echo "HOSTNAME=${local.application_name}.${local.application_data.accounts[local.environment].edw_dns_extension}" >> /etc/sysconfig/network

#### configure aws timesync (external ntp source)
echo "---configure aws timesync (external ntp source)"
AwsTimeSync(){
    local RHEL=$1
    local SOURCE=169.254.169.123

    NtpD(){
        local CONF=/etc/ntp.conf
        sed -i 's/server \\S/#server \\S/g' $CONF && \
        sed -i "20i\server $SOURCE prefer iburst" $CONF
        /etc/init.d/ntpd status >/dev/null 2>&1 \
            && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
        ntpq -p
    }
    ChronyD(){
        local CONF=/etc/chrony.conf
        sed -i 's/server \\S/#server \\S/g' $CONF && \
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

#### Install AWS cli
echo "---Installing AWS cli"
wget -O awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -o awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

#configure variables
export ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
export LOGS="${local.application_name}-EC2"
export APPNAME="${local.application_name}"
export ENV="${local.application_data.accounts[local.environment].edw_environment}"
export REGION="${local.application_data.accounts[local.environment].edw_region}"
export EFS="${aws_efs_file_system.edw.id}"
export host="$ip4 $APPNAME-$ENV $APPNAME.${local.application_data.accounts[local.environment].edw_dns_extension}"
export host2="${local.application_data.accounts[local.environment].edw_cis_ip} cis.aws.${local.application_data.accounts[local.environment].edw_environment}.legalservices.gov.uk"
export host3="${local.application_data.accounts[local.environment].edw_eric_ip} eric.aws.${local.application_data.accounts[local.environment].edw_environment}.legalservices.gov.uk"
export host4="${local.application_data.accounts[local.environment].edw_ccms_ip} ccms.aws.${local.application_data.accounts[local.environment].edw_environment}.legalservices.gov.uk"
echo $host >>/etc/hosts
echo $host2 >>/etc/hosts
echo $host3 >>/etc/hosts
echo $host4 >>/etc/hosts
mkdir -p /stage/oracle/scripts

# Disable firewall
sudo /etc/init.d/iptables stop
sudo /sbin/chkconfig iptables off

# Set up log files
echo "---creating /etc/awslogs/awscli.conf"
mkdir -p /etc/awslogs
cat > /etc/awslogs/awscli.conf <<-EOC1
[plugins]
cwlogs = cwlogs
[default]
region = $REGION
EOC1

echo "---creating /tmp/cwlogs/logstreams.conf"
mkdir -p /tmp/cwlogs

cat > /tmp/cwlogs/logstreams.conf <<-EOC2
[general]
state_file = /var/awslogs/agent-state

[oracle_alert_log_errors]
file = /oracle/software/product/10.2.0/admin/$APPNAME/bdump/alert_$APPNAME.log
log_group_name = $APPNAME-OracleAlerts
log_stream_name = {instance_id}

[rman_backup_log_errors]
file = /stage/oracle/backup_logs/*_RMAN_disk_*.log
log_group_name = $APPNAME-RMan
log_stream_name = {instance_id}

[rman_arch_backup_log_errors]
file = /stage/oracle/backup_logs/*_RMAN_disk_ARCH_*.log
log_group_name = $APPNAME-RManArch
log_stream_name = {instance_id}

[db_tablespace_space_alerts]
file = /stage/oracle/scripts/logs/freespace_alert.log
log_group_name = $APPNAME-TBSFreespace
log_stream_name = {instance_id}

[db_PMON_status_alerts]
file = /stage/oracle/scripts/logs/pmon_status_alert.log
log_group_name = $APPNAME-PMONstatus
log_stream_name = {instance_id}

[db_CDC_status_alerts]
file = /stage/oracle/scripts/logs/cdc_check.log
log_group_name = $APPNAME-CDCstatus
log_stream_name = {instance_id}
EOC2

##### METADATA #####

# #### Install_aws_logging

# echo "---Install_aws_logging"

# #Install AWS logs

# Does not work in LZ, need to fix in next ticket
# echo "---Install AWS logging"
# sudo yum install wget openssl-devel bzip2-devel libffi-devel -y
# wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
# sudo yum update rpm

#### setup_file_systems
echo "---setup_file_systems"

sudo yum install e2fsprogs

# Create Oracle DBF file file system (oradata)
sudo /sbin/mkfs.ext4 /dev/xvdf
mkdir -p /oracle/dbf
grep -qxF "/dev/xvdf /oracle/dbf ext4 defaults 0 0" /etc/fstab || echo "/dev/sdf /dev/xvdf ext4 defaults 0 0" >> /etc/fstab
sudo mount -t ext4 dev/xvdf /oracle/dbf

# Create stage (orahome) file system
sudo /sbin/mkfs.ext4 /dev/xvdg
mkdir -p /stage
chmod 777 /stage
grep -qxF "/dev/xvdg /stage ext4 defaults 0 0" /etc/fstab || echo "/dev/xvdg /stage ext4 defaults 0 0" >> /etc/fstab
sudo mount -t ext4 /dev/xvdg /stage

# Create archive file system
sudo /sbin/mkfs.ext4 /dev/xvdh
mkdir -p /oracle/ar
grep -qxF "/dev/xvdh /oracle/ar ext4 defaults 0 0" /etc/fstab || echo "/dev/xvdh /oracle/ar ext4 defaults 0 0" >> /etc/fstab
sudo mount -t ext4 /dev/xvdh /oracle/ar

#Create oracle_software
sudo /sbin/mkfs.ext4 /dev/xvdi
mkdir --p /oracle/software
grep -qxF "/dev/xvdi /oracle/software ext4 defaults 0 0" /etc/fstab || echo "/dev/xvdi /oracle/software ext4 defaults 0 0" >> /etc/fstab
sudo mount -t ext4 /dev/xvdi /oracle/software

#Create temp_undo (oraredo)
sudo /sbin/mkfs.ext4 /dev/xvdj
mkdir -p /oracle/temp_undo
grep -qxF "/dev/xvdj /oracle/temp_undo ext4 defaults 0 0" /etc/fstab || echo "/dev/xvdj /oracle/temp_undo ext4 defaults 0 0" >> /etc/fstab
sudo mount -t ext4 /dev/xvdj /oracle/temp_undo

#### setup_oracle_db_software
echo "---setup_oracle_db_software"
# Install wget / unzip
yum install -y unzip

# Create DBA user (already created in image)
groupadd dba
groupadd oinstall
useradd -d /stage/oracle -g dba oracle

#setup oracle user access
echo "---setup oracle user access"
cp -fr /home/ec2-user/.ssh /home/oracle/
chown -R oracle:dba /home/oracle/.ssh

# # Create directories and set ownership
echo "---set ownership"
chown -R oracle:dba /oracle

# # Create swap space
echo "---Create swap space"
dd if=/dev/zero of=/swapfile bs=1024M count=9
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Run Oracle installer
chmod 777 /run/cfn-init/db-install-10g.rsp

# Run installer and post install
export ORA_DISABLED_CVU_CHECKS=CHECK_RUN_LEVEL
su oracle -c "/stage/databases/database/runInstaller -silent -waitforcompletion -ignoreSysPrereqs -ignorePrereq -responseFile /run/cfn-init/db-install-10g.rsp"

/oracle/software/oraInventory/orainstRoot.sh -silent
/oracle/software/product/10.2.0/root.sh -silent

# Update oracle login script
echo "export ORACLE_SID=EDW" >> /stage/oracle/.bash_profile
echo "export ORACLE_HOME=/oracle/software/product/10.2.0" >> /stage/oracle/.bash_profile
echo "export PATH=\$ORACLE_HOME/bin:\$PATH"           >> /stage/oracle/.bash_profile

# patch the database to 10.2.0.4
chown oracle:dba /home/oracle/patchset.rsp
chmod 777 /home/oracle/patchset.rsp
su oracle -c "/stage/patches/10204/Disk1/runInstaller -silent -responseFile /home/oracle/patchset.rsp"
/oracle/software/product/10.2.0/root.sh -silent

# Create a blank database
chown oracle:dba /run/cfn-init/edw_warehouse.dbt
chmod 777 /run/cfn-init/edw_warehouse.dbt

su oracle -l -c "dbca -silent -createDatabase -templateName /run/cfn-init/edw_warehouse.dbt -gdbname $APPNAME -sid $APPNAME -responseFile NO_VALUE -characterSet WE8ISO8859P1 -sysPassword '"$SECRET"' -systemPassword '"$SECRET"' -databaseType DATA_WAREHOUSING  -datafileDestination "/oracle/dbf/" -MEMORYPERCENTAGE 70"

# create listener
chmod 777 /run/cfn-init/netca.rsp
su oracle -l -c "netca /silent /responseFile /run/cfn-init/netca.rsp"
su oracle -l -c "lsnrctl start"

mkdir -p /var/opt/oracle
chown oracle:dba /var/opt/oracle
chown -R oracle:dba /home/oracle/edwcreate
chmod -R 777 /home/oracle/edwcreate
chown oracle:dba /var/opt/oracle/passwds.sql
chmod 777 /var/opt/oracle/passwds.sql
su oracle -l -c "cp /home/oracle/edwcreate/tnsnames.ora /oracle/software/product/10.2.0/network/admin"
sed -i "s/tst/$ENV/g" /oracle/software/product/10.2.0/network/admin/tnsnames.ora
sed -i "s/^\(define EDW_SYS=\).*/\1$SECRET/" /var/opt/oracle/passwds.sql
sed -i "s/^\(define EDW_SYSTEM=\).*/\1$SECRET/" /var/opt/oracle/passwds.sql

chown -R oracle:dba /home/oracle/scripts/
chmod -R 700 /home/oracle/scripts/
chown oracle:dba /home/oracle
chmod -R 777 /home/oracle

#### Setup_owb
# Create directories for OWB setup (already created in ami)
mkdir -p /stage/owb/owb101
mkdir -p /stage/owb/owb104
mkdir -p /stage/owb/owb105

# Set permissions for staging directory
chmod -R 777 /stage/owb/

# Install OWB components
su oracle -l -c "/stage/owb/owb101/Disk1/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -waitforcompletion -responseFile /stage/owb/owb.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

su oracle -l -c "/oracle/software/product/10.2.0/oui/bin/runInstaller -silent -waitforcompletion -responseFile /stage/owb/owb104.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

su oracle -l -c "/oracle/software/product/10.2.0/oui/bin/runInstaller -silent -waitforcompletion -responseFile /stage/owb/owb105.rsp"
/oracle/software/product/10.2.0_owb/root.sh -silent

# configure environment
echo "export OMB_path=/oracle/software/product/10.2.0_owb/owb/bin/unix" >> /stage/oracle/.bash_profile

#### setup_backups:

# setup efs backup mount point
mkdir -p /home/oracle/backup_logs/
mkdir -p /backups
sed -i '/10\.202\.1\.34:\/ \/backups/d' /etc/fstab
echo "$EFS.efs.eu-west-2.amazonaws.com:/ /backups nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" >> /etc/fstab
mount /backups
mkdir -p /backups/$APPNAME_RMAN
chmod 777 /backups/$APPNAME_RMAN
sed -i "s/\/backups\/production\/MIDB_RMAN\//\/backups\/$APPNAME_RMAN/g" /home/oracle/backup_scripts/rman_s3_arch_backup_v2_1.sh
sed -i "s/\/backups\/production\/MIDB_RMAN\//\/backups\/$APPNAME_RMAN/g" /home/oracle/backup_scripts/rman_full_backup.sh
chown -R oracle:dba /home/oracle/backup*
chmod -R 740 /home/oracle/backup*

# Create /etc/cron.d/backup_cron with the cron jobs
cat <<EOC3 > /etc/cron.d/backup_cron
0 */3 * * * oracle /home/oracle/backup_scripts/rman_arch_backup_v2_1.sh $APPNAME
0 06 * * 01 oracle /home/oracle/backup_scripts/rman_full_backup.sh $APPNAME
00 07,10,13,16 * * * /home/oracle/scripts/freespace_alert.sh
00,15,30,45 * * * * /home/oracle/scripts/pmon_check.sh
EOC3

chown root:root /etc/cron.d/backup_cron
chmod 644 /etc/cron.d/backup_cron

# Add backup_cron to crontab for oracle user
yes | cp -f /etc/cron.d/backup_cron /home/oracle/crecrontab.txt
chown oracle:dba /home/oracle/crecrontab.txt
chmod 744 /home/oracle/crecrontab.txt
su oracle -c "crontab /home/oracle/crecrontab.txt"

# Set permissions for CDC scripts
chown oracle:dba /home/oracle/scripts/cdc_simple_health_check.sh
chmod 744 /home/oracle/scripts/cdc_simple_health_check.sh

chown oracle:dba /home/oracle/scripts/cdc_simple_health_check.sql
chmod 744 /home/oracle/scripts/cdc_simple_health_check.sql

chown root:root /var/cw-custom.sh
chmod 700 /var/cw-custom.sh

# Create /etc/cron.d/custom_cloudwatch_metrics with the cron job
cat <<EOC4 > /etc/cron.d/custom_cloudwatch_metrics
*/1 * * * * root /var/cw-custom.sh
EOC4

chown root:root /etc/cron.d/custom_cloudwatch_metrics
chmod 600 /etc/cron.d/custom_cloudwatch_metrics

# alert_rota.sh - set permissions
chown oracle:dba /home/oracle/scripts/alert_rota.sh
chmod 644 /home/oracle/scripts/alert_rota.sh

# Create /etc/cron.d/oracle_rotation with the cron jobs
cat <<EOC5 > /etc/cron.d/oracle_rotation
00 07 * * * oracle /home/oracle/scripts/alert_rota.sh $APPNAME
* */6 * * * oracle /home/oracle/scripts/cdc_simple_health_check.sh >> /home/oracle/scripts/logs/cdc_check.log
EOC5

chown root:root /etc/cron.d/oracle_rotation
chmod 644 /etc/cron.d/oracle_rotation

# Add oracle_rotation to crontab for oracle user
cat /etc/cron.d/oracle_rotation >> /home/oracle/crecrontab.txt
chown oracle:dba /home/oracle/crecrontab.txt
chmod 777 /home/oracle/crecrontab.txt
su oracle -c "crontab /home/oracle/crecrontab.txt"

# Download CDC scripts from S3 and set permissions
chown oracle:dba /home/oracle/scripts/cdc_simple_health_check.sh
chmod 744 /home/oracle/scripts/cdc_simple_health_check.sh

chown oracle:dba /home/oracle/scripts/cdc_simple_health_check.sql
chmod 744 /home/oracle/scripts/cdc_simple_health_check.sql

EOF
}


####### IAM role #######

resource "aws_iam_role" "edw_ec2_role" { 
  name = "${local.application_name}-ec2-instance-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]    
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
    }
  )
  path               = "/"
  assume_role_policy = <<EOF
{

    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

####### DB Instance Profile #######

resource "aws_iam_instance_profile" "edw_ec2_instance_profile" {
  name = "${local.application_name}-S3-${local.application_data.accounts[local.environment].edw_bucket_name}-edw-RW-ec2-profile"
  role = aws_iam_role.edw_ec2_role.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

####### DB Policy #######

resource "aws_iam_policy" "edw_ec2_role_policy" {
  name = "${local.application_name}-ec2-policy"
  path = "/"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-policy"
    }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
      "Statement": [
        {
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::laa-software-library",
                "arn:aws:s3:::laa-software-library/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::laa-software-library/*"
            ],
            "Effect": "Allow"
        }, 
        {
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/app/*"
            ],
            "Effect": "Allow"
        },  
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "logs:PutLogEvents",
                "ec2:DescribeInstances"
            ],
            "Resource": ["*"],
            "Effect": "Allow"
        }, 
        {
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": ["*"],
            "Effect": "Allow"
        }
    ]
}
EOF
}


####### DB Policy attachments #######

resource "aws_iam_role_policy_attachment" "edw_cw_agent_policy_attachment" {
  role       = aws_iam_role.edw_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "edw_ec2_policy_attachments" {
  role       = aws_iam_role.edw_ec2_role.name
  policy_arn = aws_iam_policy.edw_ec2_role_policy.arn
}

####### DB Instance #######

resource "aws_key_pair" "edw_ec2_key" {
  key_name   = "${local.application_name}-ssh-key-new"
  public_key = local.application_data.accounts[local.environment].edw_ec2_key
}

resource "aws_instance" "edw_db_instance" {
  ami                         = local.application_data.accounts[local.environment].edw_ec2_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].edw_ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.edw_ec2_instance_profile.id
  key_name                    = aws_key_pair.edw_ec2_key.key_name
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.edw_db_security_group.id]
  user_data_base64            = base64encode(local.db_userdata)
  user_data_replace_on_change = true


  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = local.application_data.accounts[local.environment].edw_root_volume_size
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = local.application_data.accounts[local.environment].database_ec2_name },
    { "instance-scheduling" = "skip-scheduling" }
  )
}

####### DB Volumes #######

resource "aws_ebs_volume" "orahomeVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OrahomeVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot_id # This is used for when data is being migrated

  tags = {
    Name = "${local.application_name}-orahome"
  }
}

resource "aws_volume_attachment" "orahomeVolume-attachment" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.orahomeVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "oratempVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OratempVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oraredo_snapshot_id # This is used for when data is being migrated

  tags = {
    Name = "${local.application_name}-oraredo"
  }
}

resource "aws_volume_attachment" "oratempVolume-attachment" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.oratempVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "oradataVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OradataVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oradata_snapshot_id # This is used for when data is being migrated

  tags = {
    Name = "${local.application_name}-oradata"
  }
}

resource "aws_volume_attachment" "oradataVolume-attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.oradataVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "softwareVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_SoftwareVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].software_snapshot_id # This is used for when data is being migrated

  tags = {
    Name = "${local.application_name}-software"
  }
}

resource "aws_volume_attachment" "softwareVolume-attachment" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.softwareVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "ArchiveVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_ArchiveVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oraarch_snapshot_id # This is used for when data is being migrated

  tags = {
    Name                                               = "${local.application_name}-oraarch"
    "dlm:snapshot-with:volume-hourly-35-day-retention" = "yes"
  }
}

resource "aws_volume_attachment" "ArchiveVolume-attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ArchiveVolume.id
  instance_id = aws_instance.edw_db_instance.id
}


####### DB Security Groups #######

resource "aws_security_group" "edw_db_security_group" {
  name        = "${local.application_name}-Security Group"
  description = "Security Group for DB EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-security-group"
    }
  )

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_management_cidr]
    description = "SSH access"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "SSH access"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_bastion_ssh_cidr]
    description = "SSH access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "RDS env access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_management_cidr]
    description = "RDS Workspace access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.200.96.0/19"]
    description = "RDS Ireland Workspace access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.200.32.0/19"]
    description = "RDS Appstream access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "-"
  }
}

###### DB DNS #######

resource "aws_route53_record" "edw_internal_dns_record" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.edw_db_instance.private_ip]
}