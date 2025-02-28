locals {
  db_userdata = <<EOF
#!/bin/bash

echo "Cleaning up old configs"
rm -rf /etc/cfn /etc/awslogs /tmp/cwlogs /run/cfn-init /home/oracle/fixalert /var/log/cfn*

mkdir /userdata
echo "Running prerequisite steps to set up instance..."
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/db-prereqs.sh /userdata/prereqs.sh
chmod 700 /userdata/prereqs.sh
. /userdata/prereqs.sh

## Mounting to EFS - uncomment when AMI has been applied
echo "Updating /etc/fstab"
cat <<EOT > /etc/fstab
dev/VolGroup00/LogVol00        /       ext3    defaults       1 1
LABEL=/boot     /boot   ext3    defaults        1 2
tmpfs   /dev/shm        tmpfs   defaults        0 0
devpts  /dev/pts        devpts  gid=5,mode=620  0 0
sysfs   /sys    sysfs   defaults        0 0
proc    /proc   proc    defaults        0 0
/dev/VolGroup00/LogVol01        swap    swap    defaults        0 0
/dev/xvd${local.oradata_device_name_letter} /CWA/oradata ext4 defaults  0 0
/dev/xvd${local.oraarch_device_name_letter} /CWA/oraarch ext4 defaults  0 0
/dev/xvd${local.oratmp_device_name_letter} /CWA/oratmp  ext4 defaults  0 0
/dev/xvd${local.oraredo_device_name_letter} /CWA/oraredo ext4 defaults  0 0
/dev/xvd${local.oracle_device_name_letter} /CWA/oracle  ext4 defaults  0 0
/dev/xvd${local.share_device_name_letter} /CWA/share  ext4 defaults  0 0
${aws_efs_file_system.cwa.dns_name}:/ /efs nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2
EOT

mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done

echo "Running postbuild steps to set up instance..."
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/db-postbuild.sh /userdata/postbuild.sh
chmod 700 /userdata/postbuild.sh
sed -i 's/development/${var.application_data.accounts[local.environment].env_short}/g' /userdata/postbuild.sh
. /userdata/postbuild.sh

echo "mp-${local.environment}" > /etc/cwaenv
sed -i '/^PS1=/d' /etc/bashrc
printf '\nPS1="($(cat /etc/cwaenv)) $PS1"\n' >> /etc/bashrc

echo "Setting host name"
hostname ${local.database_hostname}
echo "${local.database_hostname}" > /etc/hostname
sed -i '/^HOSTNAME/d' /etc/sysconfig/network
echo "HOSTNAME=${local.database_hostname}" >> /etc/sysconfig/network
/etc/init.d/network restart

echo "Getting IP Addresses for /etc/hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
CM_IP=""

while [ -z "$APP1_IP" ] || [ -z "$CM_IP" ]
do
  sleep 5
  APP1_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.appserver1_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  CM_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.cm_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

echo "Updating /etc/hosts"
sed -i '/${local.database_hostname}$/d' /etc/hosts
sed -i '/${local.appserver1_hostname}$/d' /etc/hosts
sed -i '/${local.cm_hostname}$/d' /etc/hosts
sed -i '/laa-oem-app$/d' /etc/hosts # This is removed for POC
echo "$PRIVATE_IP	${local.application_name_short}-db.${var.route53_zone_external}		${local.database_hostname}" >> /etc/hosts
echo "$APP1_IP	${local.application_name_short}-app1.${var.route53_zone_external}		${local.appserver1_hostname}" >> /etc/hosts
echo "$CM_IP	${local.application_name_short}-conc.${var.route53_zone_external}		${local.cm_hostname}" >> /etc/hosts

## Update the send mail url
echo "Update Sendmail configurations"
sed -i 's/${var.application_data.accounts[local.environment].old_mail_server_url}/${var.application_data.accounts[local.environment].laa_mail_relay_url}/g' /etc/mail/sendmail.cf
sed -i 's/${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /etc/mail/sendmail.cf
sed -i 's/${var.application_data.accounts[local.environment].old_mail_server_url}/${var.application_data.accounts[local.environment].laa_mail_relay_url}/g' /etc/mail/sendmail.mc
sed -i 's/${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /etc/mail/sendmail.mc
/etc/init.d/sendmail restart

echo "Update Slack alert URL for Oracle scripts"

export OLD_SLACK_ALERT_URL=`/usr/local/bin/aws --region eu-west-2 ssm get-parameter --name OLD_SLACK_ALERT_URL --with-decryption --query Parameter.Value --output text`
export SLACK_ALERT_URL=`/usr/local/bin/aws --region eu-west-2 ssm get-parameter --name SLACK_ALERT_URL --with-decryption --query Parameter.Value --output text`

find /home/oracle/scripts -type f -name '*.sh' | xargs sed -i "s/$OLD_SLACK_ALERT_URL/$SLACK_ALERT_URL/g"

sed -i "/export MAIL_ADDR/c\export MAIL_ADDR=\"$SLACK_ALERT_URL\""  /home/oracle/scripts/scan_alert.sh

echo "Adding disk space script"
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/disk-space-alert.sh /home/oracle/scripts/disk_space.sh
chmod 766 /home/oracle/scripts/disk_space.sh
sed -i "s/SLACK_ALERT_URL/$SLACK_ALERT_URL/g" /home/oracle/scripts/disk_space.sh

sed -i "/^mail.*tablespace.warning$/c\mailx -s \"\$ORACLE_SID on \$\{hostname\}: ${upper(var.application_data.accounts[local.environment].env_short)} CWA Tablespace Warning\" $SLACK_ALERT_URL < /tmp/tablespace.warning" /home/oracle/scripts/tablespace1.sh

echo "Setting up AWS EBS backup"
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
cat <<EOT > /home/oracle/scripts/aws_ebs_backup.sh
#!/bin/bash
/usr/local/bin/aws ec2 create-snapshots \
--instance-specification InstanceId=$INSTANCE_ID \
--description "AWS crash-consistent snapshots of CWA database volumes, automatically created snapshot from oracle_cron inside EC2" \
--copy-tags-from-source volume
EOT
chmod 744 /home/oracle/scripts/aws_ebs_backup.sh


echo "Setting up cron jobs"
su oracle -c "crontab -l > /home/oracle/oraclecrontab.txt"
sed -i '/disk_space.sh/d' /home/oracle/oraclecrontab.txt
echo "00 02 * * * /home/oracle/scripts/aws_ebs_backup.sh > /tmp/aws_ebs_backup.log" >> /home/oracle/oraclecrontab.txt
echo "0,30 08-17 * * 1-5 /home/oracle/scripts/disk_space.sh ${upper(var.application_data.accounts[local.environment].env_short)} ${var.application_data.accounts[local.environment].app_disk_space_alert_threshold} >/tmp/disk_space.trc 2>&1" >> /home/oracle/oraclecrontab.txt

chown oracle:oinstall /home/oracle/oraclecrontab.txt
chmod 744 /home/oracle/oraclecrontab.txt
su oracle -c "crontab /home/oracle/oraclecrontab.txt"
chown -R oracle:oinstall /home/oracle/scripts
rm -rf /etc/cron.d/oracle_cron*
ln -s /bin/mail /bin/mailx

## Remove SSH key allowed
echo "Removing old SSH key"
sed -i '/.*-general$/d' /home/ec2-user/.ssh/authorized_keys
sed -i '/.*-general$/d' /root/.ssh/authorized_keys
sed -i '/testimage$/d' /root/.ssh/authorized_keys

## Add custom metric script
echo "Adding the custom metrics script for CloudWatch"
/bin/cp -f /var/cw-custom.sh /var/cw-custom.sh.bak
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/db-cw-custom.sh /var/cw-custom.sh
chmod 700 /var/cw-custom.sh
cat <<EOT > /etc/cron.d/custom_cloudwatch_metrics
#!/bin/bash
*/1 * * * * root /var/cw-custom.sh > /dev/null 2>&1
EOT

## Additional DBA steps
su oracle -c "sed -i 's/aws.${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /CWA/oracle/product/10.2.0/db_1/appsutil/CWA_cwa-db.xml"

EOF

}

### Load userdata scripts into an S3 bucket
resource "aws_s3_object" "db_custom_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "db-cw-custom.sh"
  source      = "./cwa-poc2/db-cw-custom.sh"
  source_hash = filemd5("./cwa-poc2/db-cw-custom.sh")
}

resource "aws_s3_object" "db_prereqs_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "db-prereqs.sh"
  source      = "./cwa-poc2/scripts/db-prereqs.sh"
  source_hash = filemd5("./cwa-poc2/scripts/db-prereqs.sh")
}

resource "aws_s3_object" "db_postbuild_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "db-postbuild.sh"
  source      = "./cwa-poc2/scripts/db-postbuild.sh"
  source_hash = filemd5("./cwa-poc2/scripts/db-postbuild.sh")
}

resource "time_sleep" "wait_db_userdata_scripts" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.db_custom_script, aws_s3_object.db_prereqs_script, aws_s3_object.db_postbuild_script, aws_s3_object.disk_space_script]
}

######################################
# Database Instance
######################################

resource "aws_instance" "database" {
  ami                         = var.application_data.accounts[local.environment].cwa_poc2_db_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = var.application_data.accounts[local.environment].cwa_poc2_db_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.cwa_poc2_database.id]
  subnet_id                   = var.data_subnet_a_id
  iam_instance_profile        = aws_iam_instance_profile.cwa_poc2.id
  key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.db_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      var.tags,
      { "Name" = "${local.application_name_short}-database-root" }
    )
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    var.tags,
    { "Name" = local.database_ec2_name }
  )
  depends_on = [time_sleep.wait_db_userdata_scripts]
}

resource "aws_key_pair" "cwa" {
  key_name   = "${local.application_name_short}-ssh-key"
  public_key = var.application_data.accounts[local.environment].cwa_ec2_key
}

#################################
# Database Security Group Rules
#################################

resource "aws_security_group" "cwa_poc2_database" {
  name        = "${local.application_name_short}-${local.environment}-db-security-group"
  description = "Security Group for database"
  vpc_id      = var.shared_vpc_id

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-${local.environment}-db-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "db_bastion_ssh" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = var.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_workspace_ssh" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "SSH access from LZ Workspace"
  cidr_ipv4         = local.management_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_workspaces_1" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = var.application_data.accounts[local.environment].workspaces_local_cidr1
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_workspaces_2" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = var.application_data.accounts[local.environment].workspaces_local_cidr2
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_local_vpc_1" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "DB access from local VPC"
  cidr_ipv4         = var.shared_vpc_cidr #!ImportValue env-VpcCidr
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_local_vpc_2" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "DB access from local VPC"
  cidr_ipv4         = var.shared_vpc_cidr #!ImportValue env-VpcCidr
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
}

resource "aws_vpc_security_group_ingress_rule" "db_cp" {
  security_group_id = aws_security_group.cwa_poc2_database.id
  description       = "DB access from Cloud Platform"
  cidr_ipv4         = local.cloud_platform_cidr
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}
### Port 1571 rules allow inbound for 10.200.32.0/20 and 10.200.96.0/19 not added as unsure what they are for

resource "aws_vpc_security_group_ingress_rule" "db_app_1" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 1571
  ip_protocol                  = "tcp"
  to_port                      = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_app_2" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 32803
  ip_protocol                  = "tcp"
  to_port                      = 32803
}

resource "aws_vpc_security_group_ingress_rule" "db_app_3" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 662
  ip_protocol                  = "tcp"
  to_port                      = 662
}

resource "aws_vpc_security_group_ingress_rule" "db_app_4" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 111
  ip_protocol                  = "tcp"
  to_port                      = 111
}

resource "aws_vpc_security_group_ingress_rule" "db_app_5" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 892
  ip_protocol                  = "tcp"
  to_port                      = 892
}

resource "aws_vpc_security_group_ingress_rule" "db_app_6" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_1" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 1571
  ip_protocol                  = "tcp"
  to_port                      = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_2" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 32803
  ip_protocol                  = "tcp"
  to_port                      = 32803
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_3" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 662
  ip_protocol                  = "tcp"
  to_port                      = 662
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_4" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 111
  ip_protocol                  = "tcp"
  to_port                      = 111
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_5" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 892
  ip_protocol                  = "tcp"
  to_port                      = 892
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_6" {
  security_group_id            = aws_security_group.cwa_poc2_database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}



###############################
# Database EBS Volumes
###############################

resource "aws_ebs_volume" "oradata" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_oradata_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_oradata_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-oradata" },
  )
}

resource "aws_volume_attachment" "oradata" {
  device_name = "/dev/sd${local.oradata_device_name_letter}"
  volume_id   = aws_ebs_volume.oradata.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oracle" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_oracle_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_oracle_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-oracle" },
  )
}

resource "aws_volume_attachment" "oracle" {
  device_name = "/dev/sd${local.oracle_device_name_letter}"
  volume_id   = aws_ebs_volume.oracle.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraarch" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_oraarch_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_oraarch_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-oraarch" },
  )
}

resource "aws_volume_attachment" "oraarch" {
  device_name = "/dev/sd${local.oraarch_device_name_letter}"
  volume_id   = aws_ebs_volume.oraarch.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oratmp" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_oratmp_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_oratmp_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-oratmp" },
  )
}

resource "aws_volume_attachment" "oratmp" {
  device_name = "/dev/sd${local.oratmp_device_name_letter}"
  volume_id   = aws_ebs_volume.oratmp.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraredo" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_oraredo_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_oraredo_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-oraredo" },
  )
}

resource "aws_volume_attachment" "oraredo" {
  device_name = "/dev/sd${local.oraredo_device_name_letter}"
  volume_id   = aws_ebs_volume.oraredo.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "share" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].ebs_share_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_share_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-database-share" },
  )
}

resource "aws_volume_attachment" "share" {
  device_name = "/dev/sd${local.share_device_name_letter}"
  volume_id   = aws_ebs_volume.share.id
  instance_id = aws_instance.database.id
}

