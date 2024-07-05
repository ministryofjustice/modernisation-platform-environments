locals {
  lb_logs_bucket                        = local.application_data.accounts[local.environment].lb_access_logs_existing_bucket_name
  account_number                        = local.environment_management.account_ids[terraform.workspace]
  external_lb_idle_timeout              = 65
  external_lb_port                      = 443
  custom_header                         = "X-Custom-Header-LAA-Portal"
  force_destroy_lb_logs_bucket          = true
  lb_target_response_time_threshold     = 10
  lb_target_response_time_threshold_max = 60
  lb_unhealthy_hosts_threshold          = 0
  lb_rejected_connection_threshold      = 10
  lb_target_5xx_threshold               = 10
  lb_origin_5xx_threshold               = 10
  lb_target_4xx_threshold               = 50
  lb_origin_4xx_threshold               = 10
}

####################################
# ELB Access Logging
####################################

module "elb-logs-s3" {
  count  = local.lb_logs_bucket == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"


  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-lb-access-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = local.force_destroy_lb_logs_bucket
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/*" : "${module.elb-logs-s3[0].bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }
  }
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/*" : "${module.elb-logs-s3[0].bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}" : module.elb-logs-s3[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}

####################################
# External Portal ELB to OHS
####################################

resource "aws_lb" "external" {
  name                       = "${local.application_name}-external-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  enable_deletion_protection = local.lb_enable_deletion_protection
  idle_timeout               = local.external_lb_idle_timeout
  # drop_invalid_header_fields = true

  access_logs {
    bucket  = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
    prefix  = "${local.application_name}-external-lb"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-lb"
    },
  )
}

resource "aws_lb_listener" "external" {

  load_balancer_arn = aws_lb.external.arn
  port              = local.external_lb_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.load_balancer.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied - must access via CloudFront"
      status_code  = 403
    }
  }

  tags = local.tags

}

resource "aws_lb_listener_rule" "external" {
  listener_arn = aws_lb_listener.external.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }

  condition {
    http_header {
      http_header_name = local.custom_header
      values           = [data.aws_secretsmanager_secret_version.cloudfront.secret_string]
    }
  }
}

resource "aws_lb_target_group" "external" {
  name     = "${local.application_name}-ohs-target-group"
  port     = 7777
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  # deregistration_delay = local.target_group_deregistration_delay
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    interval            = 5
    path                = "/LAAPortal/pages/home.jsp"
    protocol            = "HTTP"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 302
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ohs-target-group"
    },
  )

}

resource "aws_lb_target_group_attachment" "ohs1" {
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.ohs_instance_1.id
  port             = 7777
}

resource "aws_lb_target_group_attachment" "ohs2" {
  count            = contains(["development", "testing"], local.environment) ? 0 : 1
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.ohs_instance_2[0].id
  port             = 7777
}


############################################
# External Portal ELB Security Group
############################################

resource "aws_security_group" "external_lb" {
  name        = "${local.application_name}-external-lb-security-group"
  description = "${local.application_name} external alb security group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "external_lb_inbound" {
  security_group_id = aws_security_group.external_lb.id
  description       = "Allows HTTPS traffic in from Cloudfront (filtered by WAF)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.external_lb_port
  ip_protocol       = "tcp"
  to_port           = local.external_lb_port
}

resource "aws_vpc_security_group_egress_rule" "external_lb_outbound" {
  security_group_id = aws_security_group.external_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

############################################
# External Portal ELB Alarms
############################################

resource "aws_cloudwatch_metric_alarm" "ext_lb_target_response_time" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-target-response-time-alarm"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  extended_statistic = "p99"
  threshold          = local.lb_target_response_time_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-target-response-time-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_target_response_time_max" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-target-response-time-alarm-maximum"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if response is longer than 60s."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "1"
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Maximum"
  threshold          = local.lb_target_response_time_threshold_max
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-target-response-time-alarm-maximum"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_unhealthy_hosts" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-unhealthy-hosts-alarm"
  alarm_description   = "The unhealthy hosts alarm triggers if your load balancer recognises there is an unhealthy host and has been there for over 2 minutes."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    TargetGroup  = aws_lb_target_group.external.arn_suffix
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "2"
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Average"
  threshold          = local.lb_unhealthy_hosts_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-unhealthy-hosts-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_rejected_connection" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-rejected-connection-count-alarm"
  alarm_description   = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to backend being busy."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "RejectedConnectionCount"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.lb_rejected_connection_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-rejected-connection-count-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_target_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-http-5xx-error-alarm"
  alarm_description   = "The number of HTTP response codes generated by the targets. This alarm will trigger if we receive 4 5XX http alerts in a 5 minute period."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.lb_target_5xx_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-http-5xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_origin_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-5xx-error-alarm"
  alarm_description   = "The number of HTTP 5XX server error codes that originate from the load balancer. This alarm will trigger if we receive 4 5XX elb alerts in a 5 minute period."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_ELB_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.lb_origin_5xx_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-5xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_target_4xx" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-http-4xx-error-alarm"
  alarm_description   = "The number of HTTP response codes generated by the targets. This alarm will trigger if we receive 4 or more 4XX http alerts in a 5 minute period."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_Target_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.lb_target_4xx_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-http-4xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ext_lb_origin_4xx" {
  alarm_name          = "${local.application_name}-${local.environment}-ext-alb-4xx-error-alarm"
  alarm_description   = "The number of HTTP 4XX client error codes that originate from the load balancer. This alarm will trigger if we receive 4 4XX elb alerts in a 5 minute period."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_ELB_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.lb_origin_4xx_threshold
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ext-alb-4xx-error-alarm"
    }
  )
}
