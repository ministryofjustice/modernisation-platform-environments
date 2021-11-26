#------------------------------------------------------------------------------
# Load Balancer - External
#------------------------------------------------------------------------------

data "aws_subnet_ids" "public" {
  vpc_id = local.vpc_id
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-public-${local.region}*"
  }
}

resource "aws_security_group" "external_lb" {

  name        = "external-lb-${local.application_name}"
  description = "Allow inbound traffic to external load balancer"
  vpc_id      = local.vpc_id

  ingress {
    description     = "https from pttp"
    from_port       = "443"
    to_port         = "443"
    protocol        = "TCP"
    cidr_blocks = ["#pttp presumably"]
  }

  egress {
    description     = "to weblogic"
    from_port       = "7777"
    to_port         = "7777"
    protocol        = "TCP"
    security_groups = [aws_security_group.weblogic_server.id]
  }

  tags = merge(
    local.tags,
    {
      Name = "external-lb-${local.application_name}"
    },
  )
}

resource "aws_lb" "external" {

  name                       = "external-${local.application_name}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = data.aws_subnet_ids.public.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "external-${local.application_name}"
    },
  )
}

resource "aws_lb_target_group" "external" {

  name                 = "external-${local.application_name}"
  port                 = "7777" # port on which targets receive traffic
  protocol             = "HTTPS"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = local.vpc_id
  
  health_check {
    enabled = true
    interval = "30"
    healthy_threshold = "3"
    matcher = "200-399"
    path = "/keepalive.htm"
    port = "7777"
    timeout = "30"
    unhealty_threshold = "5"
  }

  # access_logs { maybe we want this?
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = merge(
    local.tags,
    {
      Name = "external-${local.application_name}"
    },
  )
}

resource "aws_lb_target_group_attachment" "weblogic" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.weblogic_server.private_ip
  port             = "7777"
}

resource "aws_lb_listener" "external" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.external.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------

resource "aws_acm_certificate" "external" {
  domain_name       = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  
  tags = merge(
    local.tags,
    {
      Name = "external-${local.application_name}"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

#------------------------------------------------------------------------------
# Web Application Firewall
#------------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "waf" {
#TODO https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
}