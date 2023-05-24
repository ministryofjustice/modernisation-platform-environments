resource "aws_instance" "ec2_ebsapps" {
  count                  = local.application_data.accounts[local.environment].ebsapps_no_instances
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsapps
  ami                    = data.aws_ami.oracle_base_prereqs.id
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_ebsapps.id]
  subnet_id              = local.environment == "development" ? local.data_subnets[count.index] : local.private_subnets[count.index]
  #subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsapps
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsapps

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}
  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent
mount -a

EOF

  # AMI ebs mappings from /dev/sd[a-d]
  # root
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    tags = merge(local.tags,
      { Name = "root-block" }
    )
  }
  # swap
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }
  # temp
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }
  # home
  ebs_block_device {
    device_name = "/dev/sdd"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }

  # non-AMI mappings start at /dev/sdh
  # /export/home
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_type = "io2"
    volume_size = local.application_data.accounts[local.environment].ebsapps_exhome_size
    iops        = local.application_data.accounts[local.environment].ebsapps_default_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }
  # u01
  ebs_block_device {
    device_name = "/dev/sdi"
    volume_type = "io2"
    volume_size = local.application_data.accounts[local.environment].ebsapps_u01_size
    iops        = local.application_data.accounts[local.environment].ebsapps_default_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }
  # u03
  ebs_block_device {
    device_name = "/dev/sdj"
    volume_type = "io2"
    volume_size = local.application_data.accounts[local.environment].ebsapps_u03_size
    iops        = local.application_data.accounts[local.environment].ebsapps_default_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsapps-%s", local.application_name, local.environment, count.index + 1)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsapps]

}

resource "aws_ebs_volume" "stage" {
  count = local.is-production ? local.application_data.accounts[local.environment].ebsapps_no_instances : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_stage_size
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "stage" }
  )
}
resource "aws_volume_attachment" "stage_att" {
  count = local.is-production ? local.application_data.accounts[local.environment].ebsapps_no_instances : 0
  depends_on = [
    aws_ebs_volume.stage
  ]
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.stage[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

module "cw-ebsapps-ec2" {
  source = "./modules/cw-ec2"

  name  = "ec2-ebsapps"
  topic = aws_sns_topic.cw_alerts.arn

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold

  # Dimensions used across all alarms
  instanceId   = aws_instance.ec2_ebsapps[local.application_data.accounts[local.environment].ebsapps_no_instances - 1].id
  imageId      = data.aws_ami.oracle_base_prereqs.id
  instanceType = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsapps
  fileSystem   = "xfs"       # Linux root filesystem
  rootDevice   = "nvme0n1p1" # This is used by default for root on all the ec2 images
}
