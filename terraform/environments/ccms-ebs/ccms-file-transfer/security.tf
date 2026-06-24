### Load Balancer Security Group
resource "aws_security_group" "sftp_load_balancer" {
  name_prefix = "${local.sftp_suffix}-load-balancer-sg"
  description = "Controls access to ${local.sftp_suffix} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-load-balancer-sg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "sftp_lb_ingress_443" {
  security_group_id = aws_security_group.sftp_load_balancer.id
  #this needs to be tightened further
  cidr_ipv4   = "0.0.0.0/0"
  description = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "sftp_lb_ingress_from_lambda_443" {
  security_group_id = aws_security_group.sftp_load_balancer.id

  description                  = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id
}

resource "aws_vpc_security_group_egress_rule" "sftp_lb_egress_api" {
  security_group_id = aws_security_group.sftp_load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}

# Container Security Group
resource "aws_security_group" "ecs_tasks_sftp_security_group" {
  name        = "${local.sftp_suffix}-ecs-tasks-security-group"
  description = "Controls access to the ${local.sftp_suffix} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-ecs-tasks-security-group" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_sftp_security_group_ingress_rule" {
  security_group_id = aws_security_group.ecs_tasks_sftp_security_group.id

  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.sftp_load_balancer.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_sftp_security_group_ec2_ingress_rule" {
  security_group_id = aws_security_group.ecs_tasks_sftp_security_group.id

  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

#access to secrets manager from lambda function via vpc endpoint, keeping this disabled just for visibility as we have opened full egress on port 443
# resource "aws_vpc_security_group_egress_rule" "ecs_tasks_sftp_security_group_egress_rule_sec_manager" {
#   security_group_id = aws_security_group.ecs_tasks_sftp_security_group.id

#   description = "Allowing egress to secrets manager via vpc endpoint"
#   ip_protocol = "tcp"
#   from_port   = 443
#   to_port     = 443
#   referenced_security_group_id = data.aws_security_group.vpce_security_group.id

#   lifecycle {
#     ignore_changes = [referenced_security_group_id]
#   }
# }

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_sftp_security_group_egress_rule" {
  security_group_id = aws_security_group.ecs_tasks_sftp_security_group.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}

# Lambda Security Group
resource "aws_security_group" "process_file_from_bucket_lambda_sg" {
  name        = "${local.sftp_suffix}-process-file-from-bucket-lambda-security-group"
  description = "Controls access from the process file from bucket lambda function"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-process-file-from-bucket-lambda-security-group" }
  )
}

resource "aws_vpc_security_group_egress_rule" "process_file_from_bucket_lambda_sg_egress_rule" {
  security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sftp_load_balancer.id
}

#Opening this for slack channel webhook access from lambda function
resource "aws_vpc_security_group_egress_rule" "process_file_from_bucket_lambda_sg_egress_slack" {
  security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id

  description = "Allowing egress to slack channel webhook"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

#access to secrets manager from lambda function via vpc endpoint, keeping this disabled just for visibility as we have opened full egress on port 443
# resource "aws_vpc_security_group_egress_rule" "process_file_from_bucket_lambda_sg_egress_sec_manager" {
#   security_group_id = aws_security_group.process_file_from_bucket_lambda_sg.id

#   description = "Allowing egress to secrets manager via vpc endpoint"
#   ip_protocol = "tcp"
#   from_port   = 443
#   to_port     = 443
#   referenced_security_group_id = data.aws_security_group.vpce_security_group.id

#   lifecycle {
#     ignore_changes = [referenced_security_group_id]
#   }
# }
# EC2 Instances Security Group
resource "aws_security_group" "cluster_ec2" {
  name        = "${local.sftp_suffix}-cluster-ec2-security-group"
  description = "Controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-cluster-ec2-security-group" }
  )
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}
