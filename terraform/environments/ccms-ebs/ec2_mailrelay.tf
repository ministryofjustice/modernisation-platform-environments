#  Build EC2 
resource "aws_instance" "ec2_mailrelay" {
  instance_type          = local.application_data.accounts[local.environment].ec2_instance_type_mailrelay
  ami                    = local.application_data.accounts[local.environment].mailrelay_ami_id
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_mailrelay.id]
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

  user_data_replace_on_change = true
  user_data                   = base64encode(templatefile("./templates/ec2_user_data_mailrelay.sh", {}))

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

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-mailrelay", local.application_name, local.environment)) },
    { instance-scheduling = "skip-scheduling" },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_mailrelay]
}

resource "aws_security_group" "ec2_sg_mailrelay" {
  name        = "ec2_sg_mailrelay"
  description = "Security Group for the Mailrelay server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-mailrelay", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic_mailrelay" {
  for_each          = local.application_data.ec2_sg_mailrelay_ingress_rules
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

resource "aws_security_group_rule" "egress_traffic_mailrelay" {
  for_each          = local.application_data.ec2_sg_mailrelay_egress_rules
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
  //  source_security_group_id = aws_security_group.ec2_sg_mailrelay.id
}

module "cw-mailrelay-ec2" {
  source = "./modules/cw-ec2"

  name  = "ec2-mailrelay"
  topic = aws_sns_topic.cw_alerts.arn

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold

  # Dimensions used across all alarms
  instanceId   = aws_instance.ec2_mailrelay.id
  imageId      = local.application_data.accounts[local.environment].mailrelay_ami_id
  instanceType = local.application_data.accounts[local.environment].ec2_instance_type_mailrelay
  fileSystem   = "xfs"       # Linux root filesystem
  rootDevice   = "nvme0n1p1" # This is used by default for root on all the ec2 images
}
