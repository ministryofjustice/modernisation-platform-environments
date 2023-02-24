resource "aws_instance" "ec2_accessgate" {
  count                       = local.application_data.accounts[local.environment].accessgate_no_instances
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_accessgate
  ami                         = data.aws_ami.accessgate.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_accessgate.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device]
  }
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
  # u01
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_type = "io2"
    volume_size = local.application_data.accounts[local.environment].accessgate_u01_size
    iops        = local.application_data.accounts[local.environment].accessgate_default_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }


  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-accessgate-%s", local.application_name, local.environment, count.index + 1)) },
    { instance-scheduling = "skip-scheduling" }
  )
  depends_on = [aws_security_group.ec2_sg_accessgate]

}
/*
module "cw-accgate-ec2" {
  source = "./modules/cw-ec2"

  name        = "ec2-accgate"
  topic       = aws_sns_topic.cw_alerts.arn
  instanceIds = join(",", [for instance in aws_instance.ec2_accessgate : instance.id])

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold

}
*/
/*
resource "aws_ebs_volume" "accessgate_create" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  #for_each          = local.application_data.accounts[local.environment].accessgate_ebs
  for_each          = local.application_data.accessgate_ebs
  availability_zone = "eu-west-2a"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  type              = each.value.type
  iops              = local.application_data.accounts[local.environment].accessgate_default_iops
  size              = local.application_data.accounts[local.environment].accessgate_u01_size

  tags = merge(local.tags,
    { Name = each.key }
  )
}


resource "aws_volume_attachment" "accessgate_att" {
  for_each    = local.application_data.accessgate_ebs
  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.accessgate_create[[each.key]].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}*/