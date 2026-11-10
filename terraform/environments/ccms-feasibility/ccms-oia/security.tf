# OPAHUB ALB Security Group

resource "aws_security_group" "alb_opahub" {
  name        = "${local.opahub_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.opahub_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.opahub_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_opahub_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_opahub.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "alb_opahub_https_workspace" {
  security_group_id = aws_security_group.alb_opahub.id
  description       = "HTTPS from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}

resource "aws_vpc_security_group_egress_rule" "alb_opahub_egress_ecs_tasks_ssl" {
  security_group_id            = aws_security_group.alb_opahub.id
  description                  = "Allow LB to reach the OPAHub tasks on the WebLogic SSL port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_ssl_port
  to_port                      = local.application_data.accounts[local.environment].opa_ssl_port
  referenced_security_group_id = aws_security_group.ecs_tasks_opahub.id
}

resource "aws_vpc_security_group_egress_rule" "alb_opahub_egress_ecs_tasks_health_check" {
  security_group_id            = aws_security_group.alb_opahub.id
  description                  = "Allow LB to health check the OPAHub tasks on the WebLogic administration port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_health_check_port
  to_port                      = local.application_data.accounts[local.environment].opa_health_check_port
  referenced_security_group_id = aws_security_group.ecs_tasks_opahub.id
}

# Connector ALB Security Group

resource "aws_security_group" "alb_connector" {
  name        = "${local.connector_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.connector_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.connector_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_connector_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_connector.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_connector_egress_ecs_tasks" {
  security_group_id            = aws_security_group.alb_connector.id
  description                  = "Allow LB to reach the Connector tasks on the application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].connector_server_port
  to_port                      = local.application_data.accounts[local.environment].connector_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks_connector.id
}

# Adaptor ALB Security Group

resource "aws_security_group" "alb_adaptor" {
  name        = "${local.adaptor_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.adaptor_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.adaptor_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_adaptor_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_adaptor.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_adaptor_egress_ecs_tasks" {
  security_group_id            = aws_security_group.alb_adaptor.id
  description                  = "Allow LB to reach the Adaptor tasks on the application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                      = local.application_data.accounts[local.environment].adaptor_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks_adaptor.id
}

# OPAHub ECS Task Security Group (awsvpc mode - attached to the task ENI)

resource "aws_security_group" "ecs_tasks_opahub" {
  name        = "${local.opahub_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to the ${local.opahub_name} ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.opahub_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_opahub_from_alb_ssl" {
  security_group_id            = aws_security_group.ecs_tasks_opahub.id
  description                  = "WebLogic SSL port from the OPAHub ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_ssl_port
  to_port                      = local.application_data.accounts[local.environment].opa_ssl_port
  referenced_security_group_id = aws_security_group.alb_opahub.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_opahub_from_alb_health_check" {
  security_group_id            = aws_security_group.ecs_tasks_opahub.id
  description                  = "WebLogic administration port (health check) from the OPAHub ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_health_check_port
  to_port                      = local.application_data.accounts[local.environment].opa_health_check_port
  referenced_security_group_id = aws_security_group.alb_opahub.id
}

# OPAHub tasks: AWS APIs via VPC endpoints and internal load balancers in the private subnets
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_opahub_egress_vpce" {
  for_each = toset(local.vpce_subnets_cidr_blocks)

  security_group_id = aws_security_group.ecs_tasks_opahub.id
  description       = "Allow egress to VPC endpoints (ECR, ECS, Logs, Secrets Manager, SSM)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_opahub_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks_opahub.id
  description       = "Allow S3 access via the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_opahub_egress_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.ecs_tasks_opahub.id
  description       = "HTTPS to internal load balancers in the private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_opahub_egress_rds" {
  security_group_id            = aws_security_group.ecs_tasks_opahub.id
  description                  = "Allow outbound to the OPAHub MySQL database"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds.id
}

# Connector ECS Task Security Group (awsvpc mode - attached to the task ENI)

resource "aws_security_group" "ecs_tasks_connector" {
  name        = "${local.connector_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to the ${local.connector_name} ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.connector_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_connector_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks_connector.id
  description                  = "Application port from the Connector ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].connector_server_port
  to_port                      = local.application_data.accounts[local.environment].connector_server_port
  referenced_security_group_id = aws_security_group.alb_connector.id
}

# OPAHub/SOA via their load balancers, S3 documents bucket and Cloud Platform BC
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_https" {
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "Allow outbound HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_ebsdb" {
  security_group_id            = aws_security_group.ecs_tasks_connector.id
  description                  = "Allow outbound to the EBS DB Oracle listener"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = data.aws_security_group.ebsdb.id
}

# Adaptor ECS Task Security Group (awsvpc mode - attached to the task ENI)

resource "aws_security_group" "ecs_tasks_adaptor" {
  name        = "${local.adaptor_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to the ${local.adaptor_name} ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.adaptor_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_adaptor_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks_adaptor.id
  description                  = "Application port from the Adaptor ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                      = local.application_data.accounts[local.environment].adaptor_server_port
  referenced_security_group_id = aws_security_group.alb_adaptor.id
}

# Adaptor tasks: AWS APIs via VPC endpoints and the OPAHub ALB in the private subnets
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_adaptor_egress_vpce" {
  for_each = toset(local.vpce_subnets_cidr_blocks)

  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  description       = "Allow egress to VPC endpoints (ECR, ECS, Logs, Secrets Manager, SSM)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_adaptor_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  description       = "Allow S3 access via the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_adaptor_egress_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  description       = "HTTPS to the OPAHub ALB in the private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

# OPA Cluster EC2 Security Group (the underlying hosts)

resource "aws_security_group" "opa_cluster_ec2" {
  name        = "${local.opa_cluster_name}-ec2-sg"
  description = "Controls access to the ${local.opa_cluster_name} EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.opa_cluster_name}-ec2-sg"
  })
}

# ECS agent, ECR, SSM and CloudWatch via VPC endpoints; ECR layers and dnf repos via S3
resource "aws_vpc_security_group_egress_rule" "opa_cluster_ec2_egress_vpce" {
  for_each = toset(local.vpce_subnets_cidr_blocks)

  security_group_id = aws_security_group.opa_cluster_ec2.id
  description       = "Allow egress to VPC endpoints (ECR, ECS, Logs, Secrets Manager, SSM)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "opa_cluster_ec2_egress_s3" {
  security_group_id = aws_security_group.opa_cluster_ec2.id
  description       = "Allow S3 access via the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

# Connector / Service Adaptor Cluster EC2 Security Group (the underlying hosts)

resource "aws_security_group" "conn_saa_cluster_ec2" {
  name        = "${local.conn_saa_cluster_name}-ec2-sg"
  description = "Controls access to the ${local.conn_saa_cluster_name} EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.conn_saa_cluster_name}-ec2-sg"
  })
}

# ECS agent, ECR, SSM and CloudWatch via VPC endpoints; ECR layers and dnf repos via S3
resource "aws_vpc_security_group_egress_rule" "conn_saa_cluster_ec2_egress_vpce" {
  for_each = toset(local.vpce_subnets_cidr_blocks)

  security_group_id = aws_security_group.conn_saa_cluster_ec2.id
  description       = "Allow egress to VPC endpoints (ECR, ECS, Logs, Secrets Manager, SSM)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "conn_saa_cluster_ec2_egress_s3" {
  security_group_id = aws_security_group.conn_saa_cluster_ec2.id
  description       = "Allow S3 access via the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

# RDS Security Group

resource "aws_security_group" "rds" {
  name        = "${local.component_name}-${local.env_label}-rds-sg"
  description = "Controls access to the ${local.component_name} MySQL RDS instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_workspace" {
  security_group_id = aws_security_group.rds.id
  description       = "MySQL from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs_tasks_opahub" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from the OPAHub ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.ecs_tasks_opahub.id
}

# EBS DB SG, managed in the ccms-feasibility/ccms-ebs stack
data "aws_security_group" "ebsdb" {
  vpc_id = data.aws_vpc.shared.id
  name   = "ccms-ebs-${local.env_label}-ebsdb-sg"
}
