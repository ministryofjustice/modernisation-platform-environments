#######################################################################################################
# PPUD and WAM External Load Balancers, Listeners, Listener Certificates, Target Groups and Attachments
#######################################################################################################

#########################
# Development Environment
#########################

# PPUD Internet Facing ALB

resource "aws_lb" "PPUD-ALB" {
  # checkov:skip=CKV2_AWS_28: "ALB is already protected by WAF"
  # checkov:skip=CKV_AWS_152: "ALB target groups only have 2 targets so cross zone load balancing is not required"
  # checkov:skip=CKV_AWS_91: "ELB Logging not required"
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-external-Front-End" {
  count             = local.is-development == true ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.PPUD_internaltest_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-Target-Group[0].arn
  }
}

resource "aws_lb_target_group" "PPUD-Target-Group" {
  count    = local.is-development == true ? 1 : 0
  name     = "PPUD"
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

resource "aws_lb_target_group_attachment" "PPUD-PORTAL" {
  count            = local.is-development == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-Target-Group[0].arn
  target_id        = aws_instance.s609693lo6vw101[0].id
  port             = 443
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-1" {
  count            = local.is-development == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-Target-Group[0].arn
  target_id        = aws_instance.PPUDWEBSERVER2[0].id
  port             = 443
}

# WAM Internet Facing ALB

#tfsec:ignore:AWS0053 "The load balancer is internet facing by design."
#tfsec:ignore:AVD-AWS-0053
resource "aws_lb" "WAM-ALB" {
  # checkov:skip=CKV2_AWS_28: "ALB is already protected by WAF"
  # checkov:skip=CKV_AWS_152: "ALB target groups only have 2 targets so cross zone load balancing is not required"
  # checkov:skip=CKV_AWS_91: "ELB Logging not required"
  name               = local.application_data.accounts[local.environment].WAM_ALB
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.WAM-ALB.id]
  subnets            = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id]

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "WAM-Front-End-DEV" {
  count             = local.is-development == true ? 1 : 0
  load_balancer_arn = aws_lb.WAM-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.WAM_internaltest_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WAM-Target-Group-Dev[0].arn
  }
}

resource "aws_lb_target_group" "WAM-Target-Group-Dev" {
  count    = local.is-development == true ? 1 : 0
  name     = "WAM-Dev"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id

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

resource "aws_lb_target_group_attachment" "WAM-Portal-development" {
  count            = local.is-development == true ? 1 : 0
  target_group_arn = aws_lb_target_group.WAM-Target-Group-Dev[0].arn
  target_id        = aws_instance.s609693lo6vw105[0].id
  port             = 443
}

###########################
# Preproduction Environment
###########################

# The resource "aws_lb" "WAM-ALB" above serves the Preproduction environment

resource "aws_lb_listener" "WAM-Front-End-Preprod" {
  count             = local.is-preproduction == true ? 1 : 0
  load_balancer_arn = aws_lb.WAM-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.WAM_UAT_ALB[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WAM-Target-Group-Preprod-2[0].arn
  }
}

resource "aws_lb_listener_certificate" "WAM-Listener-Certificate-Preprod" {
  count           = local.is-preproduction == true ? 1 : 0
  listener_arn    = aws_lb_listener.WAM-Front-End-Preprod[0].arn
  certificate_arn = data.aws_acm_certificate.WAM_UAT_ALB[0].arn
}

resource "aws_lb_target_group" "WAM-Target-Group-Preprod-2" {
  count    = local.is-preproduction == true ? 1 : 0
  name     = "WAM-Preprod-2"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id

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

resource "aws_lb_target_group_attachment" "WAM-Portal-preproduction" {
  count            = local.is-preproduction == true ? 1 : 0
  target_group_arn = aws_lb_target_group.WAM-Target-Group-Preprod-2[0].arn
  target_id        = aws_instance.s618358rgvw201[0].id
  port             = 443
}

########################
# Production Environment
########################

# The resource "aws_lb" "WAM-ALB" above serves the Production environment

resource "aws_lb_listener" "WAM-Front-End-Prod" {
  count             = local.is-production == true ? 1 : 0
  load_balancer_arn = aws_lb.WAM-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.WAM_PROD_ALB[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WAM-Target-Group-Prod-2[0].arn
  }
}

resource "aws_lb_target_group" "WAM-Target-Group-Prod-2" {
  count    = local.is-production == true ? 1 : 0
  name     = "WAM-Prod-2"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id

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

resource "aws_lb_target_group_attachment" "WAM-Portal-production-2" {
  count            = local.is-production == true ? 1 : 0
  target_group_arn = aws_lb_target_group.WAM-Target-Group-Prod-2[0].arn
  target_id        = aws_instance.s618358rgvw204[0].id
  port             = 443
}





/*
resource "aws_lb_target_group" "WAM-Target-Group-Prod" {
  count    = local.is-production == true ? 1 : 0
  name     = "WAM-Prod"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "302"
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}
*/

