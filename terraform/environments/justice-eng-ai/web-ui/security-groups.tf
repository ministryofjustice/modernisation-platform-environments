# ---------- ALB security group ----------

resource "aws_security_group" "alb" {
  name        = "${local.application_resource_name}-alb"
  description = "Controls access to the builder UI ALB"
  vpc_id      = data.terraform_remote_state.justice_eng_ai.outputs.vpc_id
  tags        = merge(local.tags, { Name = "${local.application_resource_name}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from MoJ GlobalProtect/Prisma egress"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Plain HTTP ingress exists only so aws_lb_listener.http can redirect it to
# HTTPS -- the target group never receives unencrypted traffic.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from MoJ GlobalProtect/Prisma egress, redirected to HTTPS"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic from the ALB to the builder UI"
  from_port                    = var.app_container_port
  to_port                      = var.app_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
}

# ---------- UI ECS service security group ----------

resource "aws_security_group" "ecs_service" {
  name        = "${local.application_resource_name}-ecs"
  description = "Controls access to the builder UI ECS service"
  vpc_id      = data.terraform_remote_state.justice_eng_ai.outputs.vpc_id
  tags        = merge(local.tags, { Name = "${local.application_resource_name}-ecs" })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "Builder UI traffic from the ALB"
  from_port                    = var.app_container_port
  to_port                      = var.app_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs_service.id
  description       = "HTTPS egress for Bedrock, Entra and AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
