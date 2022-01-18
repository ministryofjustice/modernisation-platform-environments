resource "aws_security_group" "waf_lb" {
  description = "Security group for app load balancer, simply to implement ACL rules for the WAF"
  name        = "waf-loadbalancer-${var.networking[0].application}"
  vpc_id      = local.vpc_id
}


resource "aws_security_group_rule" "egress-to-portal" {
  depends_on               = [aws_security_group.waf_lb]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow web traffic to get to portal"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.portal-server.id
}

resource "aws_security_group_rule" "egress-to-ingestion" {
  depends_on               = [aws_security_group.waf_lb]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow web traffic to get to ingestion server"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.cjip-server.id
}

data "aws_subnet_ids" "shared-public" {
  vpc_id = local.vpc_id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

resource "aws_lb" "waf_lb" {
  depends_on                 = [aws_security_group.waf_lb]
  name                       = "waf-lb-${var.networking[0].application}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.waf_lb.id]
  subnets                    = data.aws_subnet_ids.shared-public.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "waf-lb-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group" "waf_lb_web_tg" {
  depends_on           = [aws_lb.waf_lb]
  name                 = "waf-lb-web-tg-${var.networking[0].application}"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = "30"
  vpc_id               = local.vpc_id

  health_check {
    path                = "/Secure/Default.aspx"
    port                = 80
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200" # change this to 200 when the database comes up
  }

  tags = merge(
    local.tags,
    {
      Name = "waf-lb_-g-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group" "waf_lb_ingest_tg" {
  depends_on           = [aws_lb.waf_lb, aws_lb_target_group_attachment.portal-server-attachment]
  name                 = "waf-lb-ingest-tg-${var.networking[0].application}"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = "30"
  vpc_id               = local.vpc_id

  health_check {
    path                = "/BITSWebService/BITSWebService.asmx"
    port                = 80
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200" # change this to 200 when the database comes up
  }

  tags = merge(
    local.tags,
    {
      Name = "waf-lb_-g-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group_attachment" "portal-server-attachment" {
  target_group_arn = aws_lb_target_group.waf_lb_web_tg.arn
  target_id        = aws_instance.portal-server.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ingestion-server-attachment" {
  target_group_arn = aws_lb_target_group.waf_lb_ingest_tg.arn
  target_id        = aws_instance.cjip-server.id
  port             = 80
}


resource "aws_lb_listener" "waf_lb_listener" {
  depends_on = [
    aws_acm_certificate_validation.waf_lb_cert_validation,
    aws_lb_target_group.waf_lb_web_tg,
    aws_lb_target_group.waf_lb_ingest_tg
  ]

  load_balancer_arn = aws_lb.waf_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.waf_lb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_web_tg.arn
  }
}

resource "aws_alb_listener_rule" "web_listener_rule" {
  depends_on   = [aws_lb_listener.waf_lb_listener]
  listener_arn = aws_lb_listener.waf_lb_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_web_tg.id
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }

  condition {
    host_header {
      # web.xhibit-portal.hmcts-development.modernisation-platform.service.justice.gov.uk
      values = ["web.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
    }
  }

}

resource "aws_alb_listener_rule" "ingestion_listener_rule" {
  depends_on   = [aws_lb_listener.waf_lb_listener]
  listener_arn = aws_lb_listener.waf_lb_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_ingest_tg.id
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }

  condition {
    host_header {
      # web.xhibit-portal.hmcts-development.modernisation-platform.service.justice.gov.uk
      values = ["ingest.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
    }
  }

}



resource "aws_route53_record" "waf_lb_web_dns" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external_r53_zone.zone_id
  name    = "web.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.waf_lb.dns_name
    zone_id                = aws_lb.waf_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "waf_lb_ingest_dns" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external_r53_zone.zone_id
  name    = "ingest.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
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

  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    local.application_data.accounts[local.environment].public_dns_name_web,
    local.application_data.accounts[local.environment].public_dns_name_ingestion,
  ]

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
  certificate_arn = aws_acm_certificate.waf_lb_cert.arn
  //validation_record_fqdns = [for record in aws_route53_record.waf_lb_r53_record : record.fqdn]
  validation_record_fqdns = [for dvo in aws_acm_certificate.waf_lb_cert.domain_validation_options : dvo.resource_record_name]

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

resource "aws_wafv2_web_acl_association" "aws_lb_waf_association" {
  resource_arn = aws_lb.waf_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}