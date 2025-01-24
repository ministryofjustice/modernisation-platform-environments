#This one allows the internal alb to communicate with the ecs services
resource "aws_security_group" "common_ecs_service_internal" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshift cluster, Checkov not detecting reference.
  name        = "${var.cluster_name}-ecs-service-internal"
  description = "ECS service security group"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Name" = "${var.cluster_name}-ecs-service-internal"
    },
    local.all_tags,
  )
}

#This one allows the cloudfront alb to communicate with the ecs services
resource "aws_security_group" "common_ecs_service_external" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshift cluster, Checkov not detecting reference.
  name        = "${var.cluster_name}-ecs-service-external"
  description = "ECS service security group for external facing tasks"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Name" = "${var.cluster_name}-ecs-service-external"
    },
    local.all_tags,
  )
}

resource "aws_security_group_rule" "external_service_rules" {
  for_each                 = { for idx, rule in local.combined_ingress_rules_external : idx => rule }
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = try(each.value.cidr_blocks, null)
  self                     = try(each.value.self, null)
  source_security_group_id = try(each.value.security_groups[0], null)
  description              = each.value.description
  security_group_id        = aws_security_group.common_ecs_service_external.id
}

resource "aws_security_group_rule" "allow_all_external_group" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common_ecs_service_external.id
  description       = "Allow all outbound from ecs"
}

resource "aws_security_group_rule" "internal_service_rules" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  for_each                 = { for idx, rule in local.combined_ingress_rules_internal : idx => rule }
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = try(each.value.cidr_blocks, null)
  self                     = try(each.value.self, null)
  source_security_group_id = try(each.value.security_groups[0], null)
  description              = each.value.description
  security_group_id        = aws_security_group.common_ecs_service_internal.id
}

resource "aws_security_group_rule" "allow_all_internal_group" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common_ecs_service_internal.id
  description       = "Allow all outbound from ecs"
}

#now add rule to alb internal security group
resource "aws_security_group_rule" "ecs_to_alb_rule" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.internal_alb_security_group_id
  source_security_group_id = aws_security_group.common_ecs_service_internal.id
  description              = "ALB to ECS service communication"
}
