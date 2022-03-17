resource "aws_security_group" "waf_lb" {
  description = "Security group for app load balancer, simply to implement ACL rules for the WAF"
  name        = "waf-loadbalancer-${var.networking[0].application}"
  vpc_id      = local.vpc_id
}


# resource "aws_security_group_rule" "egress-to-portal" {
#   depends_on               = [aws_security_group.waf_lb]
#   security_group_id        = aws_security_group.waf_lb.id
#   type                     = "egress"
#   description              = "allow web traffic to get to portal"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.portal-server.id
# }

resource "aws_security_group_rule" "waf_lb_allow_web_users" {
  depends_on        = [aws_security_group.waf_lb]
  security_group_id = aws_security_group.waf_lb.id
  type              = "ingress"
  description       = "allow web traffic to get to ingestion server"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks = [
    "109.152.47.104/32", # George
    "81.101.176.47/32",  # Aman
    "77.100.255.142/32", # Gary 77.100.255.142
    "82.44.118.20/32",   # Nick
    "10.175.52.4/32",    # Anthony Fletcher
    "10.182.60.51/32",   # NLE CGI proxy 
    "10.175.165.159/32", # Helen Dawes
    "10.175.72.157/32",  # Alan Brightmore
    "5.148.32.215/32",   # NCC Group proxy ITHC
    "195.95.131.110/32", # NCC Group proxy ITHC
    "195.95.131.112/32", # NCC Group proxy ITHC
    "81.152.37.83/32",   # Anand
    "77.108.144.130/32", # AL Office
    "194.33.196.1/32",   # ATOS PROXY IPS
    "194.33.196.2/32",   # ATOS PROXY IPS
    "194.33.196.3/32",   # ATOS PROXY IPS
    "194.33.196.4/32",   # ATOS PROXY IPS
    "194.33.196.5/32",   # ATOS PROXY IPS
    "194.33.196.6/32",   # ATOS PROXY IPS
    "194.33.196.46/32",  # ATOS PROXY IPS
    "194.33.196.47/32",  # ATOS PROXY IPS
    "194.33.196.48/32",  # ATOS PROXY IPS
    "194.33.192.1/32",   # ATOS PROXY IPS
    "194.33.192.2/32",   # ATOS PROXY IPS
    "194.33.192.3/32",   # ATOS PROXY IPS
    "194.33.192.4/32",   # ATOS PROXY IPS
    "194.33.192.5/32",   # ATOS PROXY IPS
    "194.33.192.6/32",   # ATOS PROXY IPS
    "194.33.192.46/32",  # ATOS PROXY IPS
    "194.33.192.47/32",  # ATOS PROXY IPS
    "194.33.192.48/32",  # ATOS PROXY IPS
    "109.146.174.114/32",# Prashanth
  ]
  ipv6_cidr_blocks = [
    "2a00:23c7:2416:3d01:9103:2cbb:5bd3:6106/128"
  ]
}

data "aws_ec2_managed_prefix_list" "cf" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


resource "aws_security_group_rule" "allow_cloudfront_ips" {
  depends_on        = [aws_security_group.waf_lb]
  security_group_id = aws_security_group.waf_lb.id
  type              = "ingress"
  description       = "allow web traffic to get to ingestion server"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cf.id]

}




data "aws_subnet_ids" "waf-shared-public" {
  vpc_id = local.vpc_id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

resource "aws_lb" "waf_lb" {

  depends_on = [
    aws_security_group.waf_lb,
  ]

  name                       = "waf-lb-${var.networking[0].application}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.waf_lb.id]
  subnets                    = data.aws_subnet_ids.waf-shared-public.ids
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.loadbalancer_logs.bucket
    prefix  = "http-lb"
    enabled = true
  }

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
    matcher             = "302" # change this to 200 when the database comes up
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


resource "aws_lb_listener" "waf_lb_listener" {
  depends_on = [
    aws_acm_certificate_validation.waf_lb_cert_validation,
    aws_lb_target_group.waf_lb_web_tg
  ]

  load_balancer_arn = aws_lb.waf_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.waf_lb_cert.arn
  # certificate_arn   = data.aws_acm_certificate.ingestion_cert.arn 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_web_tg.arn
  }
}

# resource "aws_lb_listener_certificate" "main_portal_cert" {
#   listener_arn    = aws_lb_listener.waf_lb_listener.arn
#   certificate_arn = aws_acm_certificate.waf_lb_cert.arn
# }


resource "aws_alb_listener_rule" "root_listener_redirect" {
  priority = 1

  depends_on   = [aws_lb_listener.waf_lb_listener]
  listener_arn = aws_lb_listener.waf_lb_listener.arn

  action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      path        = "/Secure/Default.aspx"
    }

  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  condition {
    host_header {
      values = [
        local.application_data.accounts[local.environment].public_dns_name_web
      ]
    }
  }

}


resource "aws_alb_listener_rule" "web_listener_rule" {
  priority     = 3
  depends_on   = [aws_lb_listener.waf_lb_listener]
  listener_arn = aws_lb_listener.waf_lb_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.waf_lb_web_tg.id
  }

  condition {
    host_header {
      values = [
        local.application_data.accounts[local.environment].public_dns_name_web
      ]
    }
  }

}

resource "aws_acm_certificate" "waf_lb_cert" {
  domain_name       = "xp-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    local.application_data.accounts[local.environment].public_dns_name_web,
  ]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_acm_certificate_validation" "waf_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.waf_lb_cert.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.waf_lb_cert.domain_validation_options : dvo.resource_record_name]
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

resource "aws_s3_bucket" "loadbalancer_logs" {
  bucket        = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}-lblogs"
  acl           = "log-delivery-write"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "loadbalancer_logs_policy" {
  bucket = aws_s3_bucket.loadbalancer_logs.bucket
  policy = data.aws_iam_policy_document.s3_bucket_lb_write.json
}


data "aws_iam_policy_document" "s3_bucket_lb_write" {

  statement {
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.loadbalancer_logs.arn}/*",
    ]

    principals {
      identifiers = ["arn:aws:iam::652711504416:root"]
      type        = "AWS"
    }
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.loadbalancer_logs.arn}/*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.loadbalancer_logs.arn}"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket" "waf_logs" {
  bucket        = "aws-waf-logs-${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}"
  acl           = "log-delivery-write"
  force_destroy = true
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
  log_destination_configs = ["${aws_s3_bucket.waf_logs.arn}"]
  resource_arn            = aws_wafv2_web_acl.waf_acl.arn
}
