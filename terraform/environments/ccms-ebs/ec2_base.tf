#  Build EC2 
resource "aws_instance" "ec2_oracle_ebs_base" {
  instance_type               = "m5d.4xlarge"
  ami                         = "ami-08f3f19e17410c832"
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device,root_block_device]
  }

  user_data = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum install -y wget unzip
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

EOF


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
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
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = "swap" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = "temp" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdd"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = "home" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-Oracle-EBS-db-base-build", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}
/*
resource "aws_ebs_volume" "export_home_base" {
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
*/
/*
resource "aws_volume_attachment" "export_home_att_base" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
/*
resource "aws_ebs_volume" "u01_base" {
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
*/
/*
resource "aws_volume_attachment" "u01_att_base" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
/*
resource "aws_ebs_volume" "arch_base" {
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
*/
/*
resource "aws_volume_attachment" "arch_att_base" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
/*
resource "aws_ebs_volume" "dbf_base" {
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
*/
/*
resource "aws_volume_attachment" "dbf_att_base" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.dbf_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
/*
resource "aws_ebs_volume" "redoA_base" {
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
*/
/*
resource "aws_volume_attachment" "redoA_att_base" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
/*
resource "aws_ebs_volume" "techst_base" {
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
*/
/*
resource "aws_volume_attachment" "techst_att_base" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst_base.id
  instance_id = aws_instance.ec2_oracle_ebs_base.id
}
*/
