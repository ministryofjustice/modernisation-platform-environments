resource "aws_security_group" "waf_lb_sg" {
  description = "Security group for app load balancer, simply to implement ACL rules for the WAF"
  name        = "waf-lb-sg-${var.networking[0].application}"
  vpc_id      = local.vpc_id

  ingress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Send everything straight to the app server"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "10.237.32.82/32"
    ]
  }
}

data "aws_subnet_ids" "shared-public" {
  vpc_id = local.vpc_id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

resource "aws_lb" "waf_lb" {
  name                       = "waf-lb-${var.networking[0].application}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.waf_lb_sg.id]
  subnets                    = data.aws_subnet_ids.shared-public.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "waf-lb-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group" "waf_lb_tg" {
  name                 = "waf-lb-tg-${var.networking[0].application}"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "waf-lb_-g-${var.networking[0].application}"
    },
  )
}


resource "aws_lb_listener" "waf_lb_listener" {
  depends_on = [
    aws_acm_certificate_validation.waf_lb_cert_validation
  ]

  load_balancer_arn = aws_lb.waf_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.waf_lb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_tg.arn
  }
}

resource "aws_alb_listener_rule" "listener_rule" {
  depends_on   = ["aws_alb_target_group.waf_lb_tg"]  
  listener_arn = "${aws_alb_listener.waf_lb_listener.arn}"  
  priority     = "${var.priority}"   
  action {    
    type             = "forward"    
    target_group_arn = "${aws_alb_target_group.waf_lb_tg.id}"  
  }   
  condition {    
    path_pattern {
      values = ["/"]  
    }    
  }

  # condition {    
  #   host-header {
  #     values = ["web.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]  
  #   }    
  # }

}



resource "aws_route53_record" "waf_lb_dns" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external_r53_zone.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.waf_lb.dns_name
    zone_id                = aws_lb.waf_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "waf_lb_cert" {
  domain_name       = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = "prod"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "external_r53_zone" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

resource "aws_route53_record" "waf_lb_r53_record" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.waf_lb_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.external_r53_zone.zone_id
}

resource "aws_acm_certificate_validation" "waf_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.waf_lb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.waf_lb_r53_record : record.fqdn]
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "waf-acl"
  description = "WAF for Xhibit Portal."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["GB"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-acl-rule-1-metric"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "waf-acl-${var.networking[0].application}"
    },
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-acl-metric"
    sampled_requests_enabled   = true
  }
}