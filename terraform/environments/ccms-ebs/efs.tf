resource "aws_instance" "rman" {
  count                  = local.application_data.accounts[local.environment].webgate_no_instances
  ami                    = data.aws_ami.oracle_db.id
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_webgate.id]
  subnet_id              = local.environment == "development" ? local.data_subnets[count.index] : local.private_subnets[count.index]

  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_webgate
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_webgate

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device]
  }
  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip nfs-utils
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

mkdir /mnt/efs
mount -t nfs4 ${aws_efs_file_system.rman_fs.dns_name}:/ /mnt/efs
echo '${aws_efs_file_system.rman_fs.dns_name}:/ /mnt/efs nfs4 defaults,_netdev 0 0' | sudo tee -a /etc/fstab

EOF

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-rmantest", local.application_name, local.environment)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )

}

resource "aws_efs_file_system" "rman_fs" {
  performance_mode = "generalPurpose"
}

resource "aws_efs_mount_target" "rman" {
  file_system_id = aws_efs_file_system.rman_fs.id
  subnet_id              = aws_instance.rman[0].subnet_id
        #local.environment == "development" ? local.data_subnets[count.index] : local.private_subnets[count.index]
}

resource "aws_security_group" "rman" {
  name_prefix = "rman"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rman_sgr" {
  security_group_id = aws_security_group.rman.id

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  source_security_group_id = aws_security_group.rman.id
}

