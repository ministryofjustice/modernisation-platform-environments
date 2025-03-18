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



# (ECS external to YJSMhub)
resource "aws_security_group_rule" "ecs_to_yjsm_external" {
  type                     = "ingress"
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_external_sg_id
}

# (ECS internal to YJSM)
resource "aws_security_group_rule" "ecs_to_yjsm_internal" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
}

# (ECS internal to YJSMhub)
resource "aws_security_group_rule" "ecs_to_yjsmhub_internal" {
  type                     = "ingress"
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
}

# (ECS internal to YJSMhub-admin)
resource "aws_security_group_rule" "ecs_to_yjsmhub_admin" {
  type                     = "ingress"
  from_port                = 8401
  to_port                  = 8401
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
}

# (ECS internal to ASSETS)
resource "aws_security_group_rule" "ecs_to_assets" {
  type                     = "ingress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.ecs_service_internal_sg_id
}

# (ASSETS)
resource "aws_security_group_rule" "assets_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = aws_security_group.yjsm_service.id
}

# (ASSETS)
resource "aws_security_group_rule" "assets_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = aws_security_group.yjsm_service.id
}

# (ESB)
resource "aws_security_group_rule" "esb_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.yjsm_service.id
  source_security_group_id = var.esb_service_sg_id
}



### TO DO LIST 
### CUG SUBNETS
### SERVICE MONITORING/ENG
### 