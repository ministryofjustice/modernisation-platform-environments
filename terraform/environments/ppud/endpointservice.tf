#################################################################################
# VPC Endpoint and Internal Load Balancer, Listener, Target Group and Attachment
#################################################################################

# Home Office VPC Attachment Production

resource "aws_vpc_endpoint_service" "HomeOffice" {
  # checkov:skip=CKV_AWS_123: "VPC Endpoint has been configured to allow automatic acceptance from the Home Office"
  count                      = local.is-production == true ? 1 : 0
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.ppud_internal_nlb[0].arn]
  tags = {
    Name = "HomeOffice-Endpoint"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "HomeOffice" {
  count                   = local.is-production == true ? 1 : 0
  vpc_endpoint_service_id = aws_vpc_endpoint_service.HomeOffice[0].id
  principal_arn           = "arn:aws:iam::${data.aws_ssm_parameter.homeoffice_account_prod[0].value}:root"
}

# Internal Network Load Balancer Production

resource "aws_lb" "ppud_internal_nlb" {
  # checkov:skip=CKV2_AWS_28: "ALB is already protected by WAF"
  # checkov:skip=CKV_AWS_152: "ALB target groups only have 2 targets so cross zone load balancing is not required"
  # checkov:skip=CKV_AWS_91: "ELB Logging not required"
  count                      = local.is-production == true ? 1 : 0
  name                       = "ppud-internal-nlb"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  security_groups            = [aws_security_group.PPUD-ALB.id]
  enable_deletion_protection = true

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

# Internal Network Load Balancer Listener Production

resource "aws_lb_listener" "nlb_forward_rule" {
  # checkov:skip=CKV2_AWS_74 "NLB do not perform SSL/TLS termination and just pass traffic through to the target group so do not use ciphers"
  count             = local.is-production == true ? 1 : 0
  load_balancer_arn = aws_lb.ppud_internal_nlb[0].arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group[0].arn
  }
}

# Internal Network Load Balancer Target Group Production

resource "aws_lb_target_group" "nlb_target_group" {
  count       = local.is-production == true ? 1 : 0
  name        = "nlb-target-group"
  port        = "443"
  protocol    = "TCP"
  target_type = "alb" # As type is ALB, you can't modify the target group attributes and will use their default values.
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

# Internal Network Load Balancer Target Group Attachment Production

resource "aws_lb_target_group_attachment" "alb_attachment" {
  count            = local.is-production == true ? 1 : 0
  target_group_arn = aws_lb_target_group.nlb_target_group[0].arn
  target_id        = aws_lb.PPUD-internal-ALB[0].id
  port             = "443"
  depends_on = [
    aws_lb_listener.nlb_forward_rule,
  ]
}