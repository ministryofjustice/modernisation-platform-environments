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

data "aws_subnets" "waf-shared-public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
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
  subnets                    = data.aws_subnets.waf-shared-public.ids
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

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.waf_lb.dns_name
    zone_id                = aws_lb.waf_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "waf_lb_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "${local.application_data.accounts[local.environment].public_dns_name_web}",
  ]

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = length(local.domain_name_sub)
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[count.index]
  records         = [local.domain_record_sub[count.index]]
  ttl             = 60
  type            = local.domain_type_sub[count.index]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "waf_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.waf_lb_cert.arn
  validation_record_fqdns = [for record in local.domain_types : record.name]
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "waf-acl"
  count       = local.is-production ? 0 : 1
  description = "WAF for Xhibit Portal."
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "block-non-gb"
    priority = 0

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["GB"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-acl-block-non-gb-rule-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-waf-common-rules"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-acl-common-rules-metric"
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
  count        = local.is-production ? 0 : 1
  web_acl_arn  = aws_wafv2_web_acl.waf_acl[0].arn
}

resource "aws_s3_bucket" "loadbalancer_logs" {
  bucket        = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}-lblogs"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "loadbalancer_logs" {
  bucket = aws_s3_bucket.loadbalancer_logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption_loadbalancer_logs" {
  bucket = aws_s3_bucket.loadbalancer_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "loadbalancer_logs_policy" {
  bucket = aws_s3_bucket.loadbalancer_logs.bucket
  policy = data.aws_iam_policy_document.s3_bucket_lb_write.json
}


data "aws_iam_policy_document" "s3_bucket_lb_write" {

  statement {
    sid = "AllowSSLRequestsOnly"
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.loadbalancer_logs.arn}/*",
      "${aws_s3_bucket.loadbalancer_logs.arn}"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }

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
  count         = local.is-production ? 0 : 1
  bucket        = "aws-waf-logs-${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "waf_logs" {
  count  = local.is-production ? 0 : 1
  bucket = aws_s3_bucket.waf_logs[0].id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption_waf_logs" {
  count  = local.is-production ? 0 : 1
  bucket = aws_s3_bucket.waf_logs[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
  count                   = local.is-production ? 0 : 1
  log_destination_configs = ["${aws_s3_bucket.waf_logs[0].arn}"]
  resource_arn            = aws_wafv2_web_acl.waf_acl[0].arn
}

resource "aws_s3_bucket_policy" "waf_logs_policy" {
  count  = local.is-production ? 0 : 1
  bucket = aws_s3_bucket.waf_logs[0].bucket
  policy = data.aws_iam_policy_document.s3_bucket_waf_logs_policy[0].json
}

data "aws_iam_policy_document" "s3_bucket_waf_logs_policy" {
  count = local.is-production ? 0 : 1
  statement {
    sid = "AllowSSLRequestsOnly"
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.waf_logs[0].arn}/*",
      "${aws_s3_bucket.waf_logs[0].arn}"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }

  statement {
    sid = "AWSLogDeliveryWrite"
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.waf_logs[0].arn}/AWSLogs/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"
      ]
    }

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"
    actions = [
      "s3:GetBucketAcl"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.waf_logs[0].arn}"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"
      ]
    }

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}
