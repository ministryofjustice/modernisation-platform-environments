#  Build EC2 
resource "aws_instance" "ec2_oracle_ebs" {
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  ami                         = data.aws_ami.oracle_base_prereqs.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsdb.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

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


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  /*
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    tags = merge(local.tags,
      { Name = "root-block" }
    )
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 200
    encrypted   = true
    tags = merge(local.tags,
      { Name = "ebs-block1" }
    )
  }
  */
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-Oracle-EBS-db", local.application_name, local.environment)) },
    { instance-scheduling = "skip-scheduling" },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsdb]
}

resource "aws_ebs_volume" "export_home" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "60"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "export/home" }
  )
}
resource "aws_volume_attachment" "export_home_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "u01" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "75"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "u01" }
  )
}
resource "aws_volume_attachment" "u01_att" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "arch" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "50"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "arch" }
  )
}
resource "aws_volume_attachment" "arch_att" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "dbf" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "8000"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "dbf" }
  )
}
resource "aws_volume_attachment" "dbf_att" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.dbf.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "redoA" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "100"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "redoA" }
  )
}
resource "aws_volume_attachment" "redoA_att" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "techst" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "50"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "techst" }
  )
}
resource "aws_volume_attachment" "techst_att" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "backup" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = "8000"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "backup" }
  )
}
resource "aws_volume_attachment" "backup_att" {
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.backup.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

/*
module "cw-ebs-ec2" {
  source = "./modules/cw-ec2"

  name        = "ec2-ebs"
  topic       = aws_sns_topic.cw_alerts.arn
  instanceIds = aws_instance.ec2_oracle_ebs.id

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold
}
*/