#  Build EC2 
resource "aws_instance" "ec2_oracle_ebs" {
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebs
  ami                         = data.aws_ami.oracle_base_prereqs.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}

  user_data = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
sudo systemctl stop amazon-ssm-agent
sudo rm -rf /var/lib/amazon/ssm/ipc/
sudo systemctl start amazon-ssm-agent
sudo mount -a

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
    { Name = lower(format("ec2-%s-%s-Oracle-EBS", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}

resource "aws_ebs_volume" "export_home" {
  availability_zone = "eu-west-2a"
  size              = "60"
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "export_home_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "u01"{
  availability_zone   = "eu-west-2a"
  size                = "75"
  type                = "io2"
  iops                = 3000
  encrypted           = true
  kms_key_id          = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "u01_att" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "arch"{
  availability_zone   = "eu-west-2a"
  size                = "50"
  type                = "io2"
  iops                = 3000
  encrypted           = true
  kms_key_id          = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "arch_att" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "dbf"{
  availability_zone   = "eu-west-2a"
  size                = "8000"
  type                = "io2"
  iops                = 3000
  encrypted           = true
  kms_key_id          = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "dbf_att" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.dbf.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "redoA"{
  availability_zone   = "eu-west-2a"
  size                = "100"
  type                = "io2"
  iops                = 3000
  encrypted           = true
  kms_key_id          = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "redoA_att" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
resource "aws_ebs_volume" "techst"{
  availability_zone   = "eu-west-2a"
  size                = "50"
  type                = "io2"
  iops                = 3000
  encrypted           = true
  kms_key_id          = data.aws_kms_key.ebs_shared.key_id
  lifecycle {
    ignore_changes = [kms_key_id]
  }
}
resource "aws_volume_attachment" "techst_att" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
