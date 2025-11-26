# CST Load Balancer Configuration

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.application_name}-load-balancer-sg"
  description = "Controls access to ${local.application_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_lb" "cst" {
  name               = "${local.application_name}-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.load_balancer.id]

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = "${local.application_name}-lb"
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb", local.application_name, local.environment)) }
  )

  depends_on = [module.s3-bucket-logging]
}

resource "aws_lb_target_group" "cst_target_group" {
  name                 = "${local.application_name}-tg"
  port                 = local.application_data.accounts[local.environment].cst_server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
    enabled         = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-tg", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Redirect all traffic from the lb to the target group
resource "aws_lb_listener" "cst" {
  load_balancer_arn = aws_lb.cst.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.cst_target_group.id
    type             = "forward"
  }
}

# Certificate

resource "aws_acm_certificate" "external" {
  validation_method         = "DNS"
  domain_name               = local.primary_domain
  subject_alternative_names = local.subject_alternative_names

  tags = merge(local.tags,
    { Environment = local.environment }
  )
}