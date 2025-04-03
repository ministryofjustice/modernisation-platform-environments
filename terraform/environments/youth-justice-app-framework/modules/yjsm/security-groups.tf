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

#TEMP RULE FOR FIXING AMI KEEP UNTIL DONE IN PROD
resource "aws_security_group_rule" "tableau_to_yjsm_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.tableau_sg_id
  description              = "tableau to yjsm ssh temp"
}

# (Subnet A to ASSETS)
resource "aws_security_group_rule" "ecs_to_assets_a" {
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  security_group_id = aws_security_group.yjsm_service.id
  cidr_blocks       = ["10.27.144.0/24"]
  description       = "ECS internal to ASSETS (Subnet A)"
}

# (Subnet B to ASSETS)
resource "aws_security_group_rule" "ecs_to_assets_b" {
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  security_group_id = aws_security_group.yjsm_service.id
  cidr_blocks       = ["10.27.145.0/24"]
  description       = "ECS internal to ASSETS (Subnet B)"
}

# (Subnet C to ASSETS)
resource "aws_security_group_rule" "ecs_to_assets_c" {
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  security_group_id = aws_security_group.yjsm_service.id
  cidr_blocks       = ["10.27.146.0/24"]
  description       = "ECS internal to ASSETS (Subnet C)"
}


### TO DO LIST 
### CUG SUBNETS
### SERVICE MONITORING/ENG
### 


10.27.144.0/24  - a
10.27.145.0/24  - b
10.27.146.0/24  - c