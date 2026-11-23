# ALB Security Group

resource "aws_security_group" "alb" {
  name        = "${local.fin_transfer_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.fin_transfer_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.fin_transfer_name}-${local.env_label}-alb-sg"
  })
}

# Includes the process-file Lambda, which runs in the private subnets
resource "aws_vpc_security_group_ingress_rule" "alb_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_workspace" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_ecs_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow LB to reach the Financial Transfers API tasks on the TLS port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

# ECS Task Security Group (awsvpc mode - attached to the task ENI)

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.fin_transfer_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to the ${local.fin_transfer_name} ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.fin_transfer_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "TLS port from the Financial Transfers ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.alb.id
}

# AWS APIs, the BC inbound bucket, the OAuth2 issuer and the Slack webhook
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_https" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_ebsdb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow outbound to the EBS DB Oracle listener"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = data.aws_security_group.ebsdb.id
}

# Cluster EC2 Security Group (the underlying hosts)

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.cluster_name}-ec2-sg"
  description = "Controls access to the ${local.cluster_name} EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-ec2-sg"
  })
}

# ECS agent, ECR, SSM and CloudWatch via VPC endpoints; ECR layers and dnf repos via S3
resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_vpce" {
  for_each = toset(local.vpce_subnets_cidr_blocks)

  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow egress to VPC endpoints (ECR, ECS, Logs, Secrets Manager, SSM)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_s3" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow S3 access via the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

# EBS DB SG, managed in the ccms-feasibility/ccms-ebs stack
data "aws_security_group" "ebsdb" {
  vpc_id = data.aws_vpc.shared.id
  name   = "ccms-ebs-${local.env_label}-ebsdb-sg"
}
