locals {
  cm_userdata = <<EOF
#!/bin/bash

echo "Cleaning up old configs"
rm -rf /etc/cfn /etc/awslogs /tmp/cwlogs /run/cfn-init /home/oracle/fixalert /var/log/cfn*

mkdir /userdata
echo "Running prerequisite steps to set up instance..."
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/app-prereqs.sh /userdata/prereqs.sh
chmod 700 /userdata/prereqs.sh
. /userdata/prereqs.sh

echo "Setting host name"
hostname ${local.cm_hostname}
echo "${local.cm_hostname}" > /etc/hostname
sed -i '/^HOSTNAME/d' /etc/sysconfig/network
echo "HOSTNAME=${local.cm_hostname}" >> /etc/sysconfig/network
/etc/init.d/network restart

echo "Getting IP Addresses for /etc/hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
CM_IP=""

while [ -z "$APP1_IP" ] || [ -z "$DB_IP" ]
do
  sleep 5
  APP1_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.appserver1_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  DB_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.database_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

echo "Updating /etc/hosts"
sed -i '/${local.database_hostname}$/d' /etc/hosts
sed -i '/${local.appserver1_hostname}$/d' /etc/hosts
sed -i '/${local.cm_hostname}$/d' /etc/hosts
echo "$DB_IP	${local.application_name_short}-db.${var.route53_zone_external}		${local.database_hostname}" >> /etc/hosts
echo "$APP1_IP	${local.application_name_short}-app1.${var.route53_zone_external}		${local.appserver1_hostname}" >> /etc/hosts
echo "$PRIVATE_IP	${local.application_name_short}-conc.${var.route53_zone_external}		${local.cm_hostname}" >> /etc/hosts


echo "Updating /etc/fstab file and mount"
cat <<EOT > /etc/fstab
/dev/VolGroup00/LogVol00        /       ext3    defaults        1 1
LABEL=/boot     /boot   ext3    defaults        1 2
tmpfs   /dev/shm        tmpfs   defaults        0 0
devpts  /dev/pts        devpts  gid=5,mode=620  0 0
sysfs   /sys    sysfs   defaults        0 0
proc    /proc   proc    defaults        0 0
/dev/VolGroup00/LogVol01        swap    swap    defaults        0 0
/dev/xvdf /CWA/app ext4 defaults 0 0
${aws_efs_file_system.cwa.dns_name}:/ /efs nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2
${local.database_hostname}:/CWA/share /CWA/share nfs rw,nolock 0 0
EOT

mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done

echo "Updating /etc/rc.local file"
cat <<EOT > /etc/rc.local
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
Xvfb :0 -screen 0 6x6x8 -pn -fp /usr/share/X11/fonts/misc -sp /root/SecurityPolicy &
export DISPLAY=${local.cm_hostname}:0.0
twm &
xhost +
EOT

echo "Running postbuild steps to set up instance..."
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/app-postbuild.sh /userdata/postbuild.sh
chmod 700 /userdata/postbuild.sh
sed -i 's/. \/CWA\/app\/appl\/APPSCWA_SERVER_HOSTNAME.env/. \/CWA\/app\/appl\/APPSCWA_${local.cm_hostname}.env/g' /userdata/postbuild.sh
sed -i 's/development/${var.application_data.accounts[local.environment].env_short}/g' /userdata/postbuild.sh
. /userdata/postbuild.sh

echo "mp-${local.environment}" > /etc/cwaenv
sed -i '/^PS1=/d' /etc/bashrc
printf '\nPS1="($(cat /etc/cwaenv)) $PS1"\n' >> /etc/bashrc

echo "Setting up crontab for applmgr"
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/disk-space-alert.sh /home/applmgr/scripts/disk_space.sh
chown applmgr /home/applmgr/scripts/disk_space.sh
chgrp oinstall /home/applmgr/scripts/disk_space.sh
chmod 744 /home/applmgr/scripts/disk_space.sh
export SLACK_ALERT_URL=`/usr/local/bin/aws --region eu-west-2 ssm get-parameter --name SLACK_ALERT_URL --with-decryption --query Parameter.Value --output text`
sed -i "s/SLACK_ALERT_URL/$SLACK_ALERT_URL/g" /home/applmgr/scripts/disk_space.sh

cat <<EOT > /home/applmgr/applmgrcrontab.txt
0,30 08-17 * * 1-5 /home/applmgr/scripts/disk_space.sh ${upper(var.application_data.accounts[local.environment].env_short)} ${var.application_data.accounts[local.environment].app_disk_space_alert_threshold} >/tmp/disk_space.trc 2>&1
EOT
chown applmgr:applmgr /home/applmgr/applmgrcrontab.txt
chmod 744 /home/applmgr/applmgrcrontab.txt
su applmgr -c "crontab /home/applmgr/applmgrcrontab.txt"

rm -rf /etc/cron.d/applmgr_cron*
ln -s /bin/mail /bin/mailx

## Update the send mail url
echo "Updating the sendmail config"
sed -i 's/${var.application_data.accounts[local.environment].old_mail_server_url}/${var.application_data.accounts[local.environment].laa_mail_relay_url}/g' /etc/mail/sendmail.cf
sed -i 's/${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /etc/mail/sendmail.cf
sed -i 's/${var.application_data.accounts[local.environment].old_mail_server_url}/${var.application_data.accounts[local.environment].laa_mail_relay_url}/g' /etc/mail/sendmail.mc
sed -i 's/${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /etc/mail/sendmail.mc
/etc/init.d/sendmail restart

## Remove SSH key allowed
echo "Removing old SSH key"
sed -i '/.*-general$/d' /home/ec2-user/.ssh/authorized_keys
sed -i '/.*-general$/d' /root/.ssh/authorized_keys
sed -i '/testimage$/d' /root/.ssh/authorized_keys

## Add custom metric script
echo "Adding the custom metrics script for CloudWatch"
rm /var/cw-custom.sh
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.scripts.id}/cm-cw-custom.sh /var/cw-custom.sh
chmod 700 /var/cw-custom.sh
#  This script will be ran by the cron job in /etc/cron.d/custom_cloudwatch_metrics

## Additional DBA Steps
echo "Updating CWA_cwa-app2.xml"
su - applmgr -c "cp /CWA/app/appl/admin/CWA_cwa-app2.xml /CWA/app/appl/admin/CWA_cwa-app2.xml.tf_backup"
sed -i 's/aws.${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /CWA/app/appl/admin/CWA_cwa-app2.xml
sed -i 's/${var.application_data.accounts[local.environment].old_domain_name}/${var.route53_zone_external}/g' /CWA/app/appl/admin/CWA_cwa-app2.xml
sed -i 's/cwa.${var.application_data.accounts[local.environment].old_domain_name}/${resource.aws_route53_record.external.name}/g' /CWA/app/appl/admin/CWA_cwa-app2.xml
sed -i 's/db_admin@legalservices.gov.uk/db_admin@${resource.aws_route53_record.external.name}/g' /CWA/app/appl/admin/CWA_cwa-app2.xml

EOF

}

### Load custom metric script into an S3 bucket
resource "aws_s3_object" "cm_custom_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "cm-cw-custom.sh"
  source      = "./cwa-poc2/cm-cw-custom.sh"
  source_hash = filemd5("./cwa-poc2/cm-cw-custom.sh")
}

resource "time_sleep" "wait_cm_custom_script" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.cm_custom_script, aws_s3_object.app_prereqs_script, aws_s3_object.app_postbuild_script, aws_s3_object.disk_space_script]
}

######################################
# concurrent_manager Instance
######################################

resource "aws_instance" "concurrent_manager" {
  ami                         = var.application_data.accounts[local.environment].cwa_poc2_cm_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = var.application_data.accounts[local.environment].cwa_poc2_cm_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.cwa_poc2_concurrent_manager.id]
  subnet_id                   = var.private_subnet_a_id
  iam_instance_profile        = aws_iam_instance_profile.cwa_poc2.id
  key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.cm_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      var.tags,
      { "Name" = "${local.application_name_short}-concurrent-manager-root" }
    )
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    var.tags,
    { "Name" = local.cm_ec2_name },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "no" } : { "snapshot-with-daily-35-day-retention" = "yes" }
  )

  depends_on = [time_sleep.wait_cm_custom_script] # This resource creation will be delayed to ensure object exists in the bucket

}

#################################
# concurrent_manager Security Group Rules
#################################

resource "aws_security_group" "cwa_poc2_concurrent_manager" {
  name        = "${local.application_name_short}-${local.environment}-cm-security-group"
  description = "Security Group for concurrent_manager"
  vpc_id      = var.shared_vpc_id

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-${local.environment}-cm-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "cm_outbound" {
  security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "cm_bastion_ssh" {
  security_group_id            = aws_security_group.cwa_poc2_concurrent_manager.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = var.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "cm_workspace_ssh" {
  security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  description       = "SSH access from LZ Workspace"
  cidr_ipv4         = local.management_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "cm_self" {
  security_group_id            = aws_security_group.cwa_poc2_concurrent_manager.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.cwa_poc2_concurrent_manager.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

resource "aws_vpc_security_group_ingress_rule" "cm_app" {
  security_group_id            = aws_security_group.cwa_poc2_concurrent_manager.id
  description                  = "Access from the Application Server"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

###############################
# concurrent_manager EBS Volumes
###############################

resource "aws_ebs_volume" "concurrent_manager" {
  availability_zone = "eu-west-2a"
  size              = var.application_data.accounts[local.environment].cwa_poc2_ebs_concurrent_manager_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id
  snapshot_id       = var.application_data.accounts[local.environment].cwa_poc2_concurrent_manager_snapshot_id # This is used for when data is being migrated

  lifecycle {
    replace_triggered_by = [
      aws_instance.concurrent_manager.id
    ]
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-concurrent-manager-data" },
  )
}

resource "aws_volume_attachment" "concurrent_manager" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.concurrent_manager.id
  instance_id = aws_instance.concurrent_manager.id
}
