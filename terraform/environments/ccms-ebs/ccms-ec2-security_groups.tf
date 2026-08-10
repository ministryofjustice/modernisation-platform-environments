data "aws_security_group" "process_file_from_bucket_lambda_sg" {
  filter {
    name   = "tag:Name"
    values = [format("%s-sftp-process-file-from-bucket-lambda-security-group", local.application_name)]
  }
  vpc_id = data.aws_vpc.shared.id
}

data "aws_security_group" "sftp_load_balancer" {
  filter {
    name   = "tag:Name"
    values = [format("%s-sftp-load-balancer-sg", local.application_name)]
  }
  vpc_id = data.aws_vpc.shared.id
}

data "aws_security_group" "cluster_ec2" {
  filter {
    name   = "tag:Name"
    values = [format("%s-sftp-cluster-ec2-security-group", local.application_name)]
  }
  vpc_id = data.aws_vpc.shared.id
}

data "aws_security_group" "ecs_tasks_sftp_security_group" {
  filter {
    name   = "tag:Name"
    values = [format("%s-sftp-ecs-tasks-security-group", local.application_name)]
  }
  vpc_id = data.aws_vpc.shared.id
}

locals {
  excluded_sgs = [
    data.aws_security_group.process_file_from_bucket_lambda_sg.id,
    data.aws_security_group.sftp_load_balancer.id,
    data.aws_security_group.cluster_ec2.id,
    data.aws_security_group.ecs_tasks_sftp_security_group.id,
    aws_security_group.ec2_sg_ftp.id,
    aws_security_group.lambda_security_group.id
    ]
}

# Rule for all ingress/egress within the environment
resource "aws_security_group_rule" "all_internal_ingress_traffic" {
  for_each          = { for sub in data.aws_security_groups.all_security_groups.ids : sub => sub if !contains(local.excluded_sgs, sub) }
  security_group_id = each.value
  type              = "ingress"
  description       = "All internal traffic"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "all_internal_egress_traffic" {
  for_each          = { for sub in data.aws_security_groups.all_security_groups.ids : sub => sub if !contains(local.excluded_sgs, sub) }
  security_group_id = each.value
  #security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type        = "egress"
  description = "All internal traffic"
  protocol    = "all"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  lifecycle {
    create_before_destroy = true
  }
}

