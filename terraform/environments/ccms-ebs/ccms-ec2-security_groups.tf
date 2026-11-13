
# These security groups are managed in the ccms-file-transfer root module (separate
# state), so they can't be referenced via aws_security_group.<name>.id here - look
# them up by their Name tag instead.
data "aws_security_group" "sftp_process_file_from_bucket_lambda_sg" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-sftp-process-file-from-bucket-lambda-security-group"]
  }
}

data "aws_security_group" "sftp_load_balancer" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-sftp-load-balancer-sg"]
  }
}

data "aws_security_group" "sftp_cluster_ec2" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-sftp-cluster-ec2-security-group"]
  }
}

data "aws_security_group" "sftp_ecs_tasks_security_group" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-sftp-ecs-tasks-security-group"]
  }
}

data "aws_security_group" "lambda_security_group" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-lambda-sg"]
  }
}

data "aws_security_group" "ec2_sg_ftp" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = [lower(format("sg-%s-%s-FTP", local.application_name, local.environment))]
  }
}

locals {
  excluded_sgs = [
    data.aws_security_group.sftp_process_file_from_bucket_lambda_sg.id,
    data.aws_security_group.sftp_load_balancer.id,
    data.aws_security_group.sftp_cluster_ec2.id,
    data.aws_security_group.sftp_ecs_tasks_security_group.id,
    data.aws_security_group.lambda_security_group.id,
    data.aws_security_group.ec2_sg_ftp.id,
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

