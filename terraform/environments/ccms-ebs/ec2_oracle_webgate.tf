resource "aws_instance" "ec2_webgate" {
  count                  = local.application_data.accounts[local.environment].webgate_no_instances
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  ami                    = data.aws_ami.webgate.id
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_webgate.id]
  subnet_id              = local.environment == "development" ? local.data_subnets[count.index] : local.private_subnets[count.index]
  #subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_webgate
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_webgate

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  # Also includes ebs_optimized and cpu_core_count due to changing instance family from c5d.2xlarge to m5d.large
  lifecycle {
    ignore_changes = [
      ebs_block_device,
      ebs_optimized,
      cpu_core_count
    ]
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
    volume_size = local.application_data.accounts[local.environment].webgate_u01_size
    iops        = local.application_data.accounts[local.environment].webgate_default_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
  }


  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-webgate-%s", local.application_name, local.environment, count.index + 1)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_webgate]

}


module "cw-webgate-ec2" {
  source = "./modules/cw-ec2"
  count  = local.application_data.accounts[local.environment].webgate_no_instances
  
  short_env     = local.application_data.accounts[local.environment].short_env
  name          = "ec2-webgate-${count.index + 1}"
  topic         = aws_sns_topic.cw_alerts.arn
  instanceId    = aws_instance.ec2_webgate[count.index].id
  imageId       = data.aws_ami.webgate.id
  instanceType  = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  fileSystem    = "xfs"       # Linux root filesystem
  rootDevice    = "nvme0n1p1" # This is used by default for root on all the ec2 images

  cpu_eval_periods  = local.application_data.cloudwatch_ec2.cpu.eval_periods
  cpu_datapoints    = local.application_data.cloudwatch_ec2.cpu.eval_periods
  cpu_period        = local.application_data.cloudwatch_ec2.cpu.period
  cpu_threshold     = local.application_data.cloudwatch_ec2.cpu.threshold

  mem_eval_periods  = local.application_data.cloudwatch_ec2.mem.eval_periods
  mem_datapoints    = local.application_data.cloudwatch_ec2.mem.eval_periods
  mem_period        = local.application_data.cloudwatch_ec2.mem.period
  mem_threshold     = local.application_data.cloudwatch_ec2.mem.threshold

  disk_eval_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  disk_datapoints    = local.application_data.cloudwatch_ec2.disk.eval_periods
  disk_period        = local.application_data.cloudwatch_ec2.disk.period
  disk_threshold     = local.application_data.cloudwatch_ec2.disk.threshold

  insthc_eval_periods  = local.application_data.cloudwatch_ec2.insthc.eval_periods
  insthc_period        = local.application_data.cloudwatch_ec2.insthc.period
  insthc_threshold     = local.application_data.cloudwatch_ec2.insthc.threshold

  syshc_eval_periods  = local.application_data.cloudwatch_ec2.syshc.eval_periods
  syshc_period        = local.application_data.cloudwatch_ec2.syshc.period
  syshc_threshold     = local.application_data.cloudwatch_ec2.syshc.threshold

}
