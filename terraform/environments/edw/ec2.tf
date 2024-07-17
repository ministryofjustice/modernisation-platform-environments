locals {
  db_userdata = <<EOF
#!/bin/bash

##### USERDATA #####

####install missing package and hostname change
yum -y install libXp.i386
yum -y install sshpass
echo "HOSTNAME="${local.application_data.accounts[local.environment].edw_AppName}"."${local.application_data.accounts[local.environment].edw_dns_extension}"" >> /etc/sysconfig/network

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



##### METADATA #####

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
sed -i "s/tst/${local.application_data.accounts[local.environment].edw_environment}/g" /oracle/software/product/10.2.0/network/admin/tnsnames.ora
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
  path = "/"
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
  path               = "/" 
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
  ami                    = local.application_data.accounts[local.environment].edw_ec2_ami_id
  availability_zone      = "eu-west-2a"
  instance_type          = local.application_data.accounts[local.environment].edw_ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.edw_ec2_instance_profile.id
  key_name               = aws_key_pair.edw_ec2_key.key_name
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.edw_db_security_group.id]
  user_data_base64            = base64encode(local.db_userdata)
  user_data_replace_on_change = false
  
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
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_data.accounts[local.environment].database_ec2_name}"
    }
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
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-orahome"
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
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-oraredo"
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
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-oradata"
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
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-software"
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
    Name                                               = "${local.application_data.accounts[local.environment].edw_AppName}-oraarch"
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
    cidr_blocks = ["10.26.56.0/21"]
    description = "SCP temp"
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
    cidr_blocks = ["10.26.56.0/21"]
    description = "-"
  }

  ingress {
    from_port   = 1158
    to_port     = 1158
    protocol    = "tcp"
    cidr_blocks = ["10.200.0.0/20"]
    description = "-"
  }

  ingress {
    from_port   = 1158
    to_port     = 1158
    protocol    = "tcp"
    cidr_blocks = ["10.202.0.0/20"]
    description = "-"
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
    cidr_blocks = ["10.200.96.0/19"]
    description = "RDS Ireland Workspace access"
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
    cidr_blocks = ["10.200.32.0/19"]
    description = "RDS Appstream access"
  }

  egress {
    from_port   = 0
    to_port     = -1
    protocol    = "tcp"
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