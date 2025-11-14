#create YJSM security group
resource "aws_security_group" "yjsm_service" {
  name        = "YJSM"
  description = "YJSM instance security group"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Name" = "yjsm service"
    },
    local.all_tags,
  )
}

resource "aws_security_group_rule" "yjsm_allow_all_internal_group" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yjsm_service.id
  description       = "Allow all outbound from yjsm"
}


# (ECS external to YJSMhub)
resource "aws_security_group_rule" "ecs_to_yjsm_external" {
  type                     = "ingress"
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_external_sg_id
  description              = "ECS external to YJSMHub"
}

# (ECS internal to YJSM)
resource "aws_security_group_rule" "ecs_to_yjsm_internal" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
  description              = "ECS internal to YJSM"
}

# (ECS internal to YJSMhub)
resource "aws_security_group_rule" "ecs_to_yjsmhub_internal" {
  type                     = "ingress"
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
  description              = "ECS internal to YJSMHub"
}

# (ECS internal to YJSMhub-admin)
resource "aws_security_group_rule" "ecs_to_yjsmhub_admin" {
  type                     = "ingress"
  from_port                = 8401
  to_port                  = 8401
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
  description              = "ECS internal to YJSMHub-admin"
}

# (ECS internal to ASSETS)
resource "aws_security_group_rule" "ecs_to_assets" {
  type                     = "ingress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
  description              = "ECS internal to ASSETS"
}

# (ESB)
resource "aws_security_group_rule" "esb_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.esb_service_sg_id
  description              = "YJSM to ESB"
}


# YJSM to RDS
resource "aws_security_group_rule" "allow_postgres_from_yjsm" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_cluster_security_group_id
  source_security_group_id = aws_security_group.yjsm_service.id
  description              = "YJSM to RDS"
}

# YJSM to ALB
resource "aws_security_group_rule" "allow_alb_from_yjsm" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.alb_security_group_id
  source_security_group_id = aws_security_group.yjsm_service.id
  description              = "YJSM to YJAF Internal ALB"
}


#YJSM to ECS
resource "aws_security_group_rule" "yjsm_to_ecsint_rule" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.ecs_service_internal_sg_id
  source_security_group_id = aws_security_group.yjsm_service.id
  description              = "YJSM to ECSint communication"
}

# Access from Tableau to YJSM 
resource "aws_security_group_rule" "tableau_to_yjsm_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.tableau_sg_id
  description              = "tableau to yjsm ssh"
}

# SSH from Management server to YJSM
resource "aws_security_group_rule" "mgmt_ssh_to_yjsm" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.management_server_sg_id
  description              = "mgmt ssh to yjsm"
}

# ECS to ASSETS SUBNETS
resource "aws_security_group_rule" "ecs_subnets_assets" {
  for_each          = { for s in var.private_subnet_list : s.availability_zone => s }
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  security_group_id = aws_security_group.yjsm_service.id
  cidr_blocks       = [each.value.cidr_block]
  description       = "ECS internal to ASSETS (${each.key})"
}


### CUG RANGES
resource "aws_ec2_managed_prefix_list" "custom_internal" {
  name           = "custom-internal-access"
  address_family = "IPv4"
  max_entries    = 1
}

resource "aws_ec2_managed_prefix_list_entry" "custom_internal_entry" {
  prefix_list_id = aws_ec2_managed_prefix_list.custom_internal.id
  cidr           = "10.20.224.0/21"
  description    = "YJB CUG RANGE 1"
}

resource "aws_security_group_rule" "prefix_list" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.yjsm_service.id
  prefix_list_ids   = [aws_ec2_managed_prefix_list.custom_internal.id]
  description       = "Allow HTTP from internal prefix list"
}


### SERVICE MONITORING/ENG
resource "aws_security_group_rule" "monitoring_to_yjsm" {
  type                     = "ingress"
  from_port                = 8400
  to_port                  = 8400
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.management_server_sg_id
  description              = "Service access (YJSM 8400)"
}
resource "aws_security_group_rule" "yjsm_from_monitoring" {
  type                     = "egress"
  from_port                = 8400
  to_port                  = 8400
  protocol                 = "tcp"
  security_group_id        = var.management_server_sg_id
  source_security_group_id = aws_security_group.yjsm_service.id
  description              = "Service access (YJSM 8400)"
}