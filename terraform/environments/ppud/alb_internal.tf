######################################################################################################
# PPUD and WAM Internal Load Balancers, Listeners, Listener Certificates, Target Groups and Attachments
#######################################################################################################

#########################
# Development Environment
#########################

# N/A

###########################
# Preproduction Environment
###########################

# PPUD MoJ Internal Facing ALB

resource "aws_lb" "PPUD-internal-ALB" {
  # checkov:skip=CKV_AWS_152: "ALB target groups only have 2 targets so cross zone load balancing is not required"
  # checkov:skip=CKV_AWS_91: "ELB Logging not required"
  count              = local.is-development == false ? 1 : 0
  name               = local.application_data.accounts[local.environment].PPUD_Internal_ALB
  internal           = true
  idle_timeout       = 240
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-Front-End-Preprod" {
  count             = local.is-preproduction == true ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-internal-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.PPUD_UAT_ALB[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  }
}

resource "aws_lb_listener_certificate" "PPUD-Training-Certificate" {
  count           = local.is-preproduction == true ? 1 : 0
  listener_arn    = aws_lb_listener.PPUD-Front-End-Preprod[0].arn
  certificate_arn = data.aws_acm_certificate.PPUD_Training_ALB[0].arn
}

resource "aws_lb_listener_certificate" "PPUD-Listener-Certificate-Preprod" {
  count           = local.is-preproduction == true ? 1 : 0
  listener_arn    = aws_lb_listener.PPUD-Front-End-Preprod[0].arn
  certificate_arn = data.aws_acm_certificate.PPUD_UAT_ALB[0].arn
}

resource "aws_lb_target_group" "PPUD-internal-Target-Group" {
  count    = local.is-development == false ? 1 : 0
  name     = local.application_data.accounts[local.environment].PPUD_Target
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id
  stickiness {
    cookie_duration = 86400
    type            = "lb_cookie"
    enabled         = true
  }

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 443
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "302"
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-internal-preproduction" {
  count            = local.is-preproduction == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  target_id        = aws_instance.s618358rgvw023[0].id
  port             = 443
}

########################
# Production Environment
########################

# The resource "aws_lb" "PPUD-internal-ALB" above serves the Production environment

resource "aws_lb_listener" "PPUD-Front-End-Prod" {
  count             = local.is-production == true ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-internal-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.PPUD_PROD_ALB[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  }
}

# The resource "aws_lb_target_group" "PPUD-internal-Target-Group" above serves the Production environment

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-internal-production" {
  count            = local.is-production == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  target_id        = aws_instance.s618358rgvw019[0].id
  port             = 443
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-internal-production-1" {
  count            = local.is-production == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  target_id        = aws_instance.s618358rgvw020[0].id
  port             = 443
}
