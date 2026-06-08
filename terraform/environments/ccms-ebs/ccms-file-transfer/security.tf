### Load Balancer Security Group
resource "aws_security_group" "sftp_bc_load_balancer" {
  name_prefix = "${local.application_name}-sftp-bc-load-balancer-sg"
  description = "Controls access to ${local.application_name}-sftp-bc lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "sftp_bc_lb_ingress_443" {
  security_group_id = aws_security_group.sftp_bc_load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  description = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "sftp_bc_lb_ingress_from_lambda_443" {
  security_group_id = aws_security_group.sftp_bc_load_balancer.id

  description                  = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id
}

resource "aws_vpc_security_group_egress_rule" "sftp_bc_lb_egress_api" {
  security_group_id = aws_security_group.sftp_bc_load_balancer.id

  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.cluster_fargate_sg.id
}

# Fargate Security Group
resource "aws_security_group" "cluster_fargate_sg" {
  name        = "${local.application_name}-cluster-fargate-security-group"
  description = "Controls access to the cluster fargate tasks"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-%s-fargate-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "cluster_fargate_sg_ingress_all" {
  security_group_id = aws_security_group.cluster_fargate_sg.id

  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.sftp_bc_load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_fargate_sg_egress_all" {
  security_group_id = aws_security_group.cluster_fargate_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# Fargate Security Group
resource "aws_security_group" "process_file_from_bucket_lambda_sg" {
  name        = "${local.application_name}-process-file-from-bucket-lambda-security-group"
  description = "Controls access from the process file from bucket lambda function"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-%s-process-file-from-bucket-lambda-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "process_file_from_bucket_lambda_sg_egress_all" {
  security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sftp_bc_load_balancer.id
}

#Opening this for aws secret manager and slack channel webhook access from lambda function
resource "aws_vpc_security_group_egress_rule" "process_file_from_bucket_lambda_sg_egress_all" {
  security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  cidr_ipv4                    = "0.0.0.0/0"
}