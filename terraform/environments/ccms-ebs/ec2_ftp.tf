#  Build EC2 
resource "aws_instance" "ec2_ftp" {
  instance_type          = local.application_data.accounts[local.environment].ec2_instance_type_ftp
  ami                    = local.application_data.accounts[local.environment].ftp_ami_id
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_ftp.id]
  subnet_id              = local.environment == "development" ? data.aws_subnet.data_subnets_a.id : data.aws_subnet.private_subnets_a.id
  #subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device, root_block_device]
  }
  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1

yum install -y wget unzip vsftpd jq s3fs-fuse
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
amazon-linux-extras install -y epel

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

cat > /etc/mount_s3.sh <<- EOM
#!/bin/bash

B=(laa-ccms-inbound-${local.application_data.accounts[local.environment].lz_ftp_bucket_environment} laa-ccms-outbound-${local.application_data.accounts[local.environment].lz_ftp_bucket_environment} laa-cis-outbound-${local.application_data.accounts[local.environment].lz_ftp_bucket_environment} laa-cis-inbound-${local.application_data.accounts[local.environment].lz_ftp_bucket_environment} bacway-${local.application_data.accounts[local.environment].lz_ftp_bucket_environment}-eu-west-2-${local.application_data.accounts[local.environment].lz_aws_account_id_env})

C=\$(aws secretsmanager get-secret-value --secret-id ftp-s3-${local.environment}-aws-key --region eu-west-2)
K=\$(jq -r '.SecretString' <<< \$${C} |cut -d'"' -f2)
S=\$(jq -r '.SecretString' <<< \$${C} |cut -d'"' -f4)
F=/etc/passwd-s3fs
echo "\$${K}:\$${S}" > "\$${F}"
chmod 600 \$${F}

for b in "\$${B[@]}"; do
  D=/mnt/\$${b}

  if [[ -d \$${D} ]]; then
    echo "\$${D} exists."
  else
    mkdir -p \$${D}
  fi

  s3fs \$${b} \$${D} -o passwd_file=\$${F}
  if [[ \$? -eq 0 ]]; then
    s3fs \$${b} \$${D} -o passwd_file=\$${F}
    echo "\$${b} has been mounted in \$${D}"
  else
    echo "\$${b} has not been mounted! Please investigate."
  fi
done

rm \$${F}
EOM

chmod +x /etc/mount_s3.sh

chmod +x /etc/rc.d/rc.local
echo "/etc/mount_s3.sh" >> /etc/rc.local
systemctl start rc-local.service

EOF
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    iops        = 3000
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = "root-block" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 20
    //    iops = 12000
    encrypted  = true
    kms_key_id = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = "swap" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-FTP", local.application_name, local.environment)) },
    { instance-scheduling = "skip-scheduling" },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_ftp]
}

module "cw-ftp-ec2" {
  source = "./modules/cw-ec2"

  name  = "ec2-ftp"
  topic = aws_sns_topic.cw_alerts.arn

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold

  # Dimensions used across all alarms
  instanceId   = aws_instance.ec2_ftp.id
  imageId      = local.application_data.accounts[local.environment].ftp_ami_id
  instanceType = local.application_data.accounts[local.environment].ec2_instance_type_ftp
  fileSystem   = "xfs"       # Linux root filesystem
  rootDevice   = "nvme0n1p1" # This is used by default for root on all the ec2 images
}
