#  Build EC2 
resource "aws_instance" "ec2_oracle_ebs_dr" {
  count = local.environment == "development" ? 1 : 0

  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  ami                         = data.aws_ami.oracle_db_dr.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsdb.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsdb
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsdb

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}
  lifecycle {
    ignore_changes = [ebs_block_device, user_data_replace_on_change, user_data]
  }
  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

# AWS CW Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

# AWS SSM Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

# s3Fuse
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse/
./autogen.sh
./configure
make
make install
cd /
mkdir /rman
s3fs -o iam_role="role_stsassume_oracle_base" -o url="https://s3.eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o dbglevel=info -o curldbg -o allow_other -o use_cache=/tmp ccms-ebs-${local.environment}-dbbackup /rman
echo "ccms-ebs-${local.environment}-dbbackup /rman fuse.s3fs _netdev,allow_other,url=https://s3.eu-west-2.amazonaws.com,iam_role=role_stsassume_oracle_base 0 0" >> /etc/fstab

EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsdb-dr-test", local.application_name, local.environment)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling }
  )
  depends_on = [aws_security_group.ec2_sg_ebsdb]
}

resource "aws_ebs_volume" "export_home_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_exhome
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "export/home_dr" }
  )
}
resource "aws_volume_attachment" "export_home_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "u01_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_u01
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "u01_dr" }
  )
}
resource "aws_volume_attachment" "u01_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "arch_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_arch
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "arch_dr" }
  )
}
resource "aws_volume_attachment" "arch_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "dbf_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "dbf_dr" }
  )
}
resource "aws_volume_attachment" "dbf_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.dbf_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "redoA_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoA
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "redoA_dr" }
  )
}
resource "aws_volume_attachment" "redoA_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "techst_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_techst
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "techst_dr" }
  )
}
resource "aws_volume_attachment" "techst_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
resource "aws_ebs_volume" "backup_dr" {
  count = local.environment == "development" ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_backup
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "backup_dr" }
  )
}
resource "aws_volume_attachment" "backup_att_dr" {
  count       = local.environment == "development" ? 1 : 0
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.backup_dr[0].id
  instance_id = aws_instance.ec2_oracle_ebs_dr[0].id
}
