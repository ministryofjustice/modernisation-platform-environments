locals {
  ip_set_list = [for ip in split("\n", chomp(file("${path.module}/waf_ip_set.txt"))) : ip]
}

resource "aws_wafv2_ip_set" "wafmanualallowset" {
  name = "${upper(local.application_name)}-manual-allow-set"

  # Ranges from https://github.com/ministryofjustice/laa-apex/blob/master/aws/application/application_stack.template
  # removed redundant ip addresses such as RedCentric access and AWS Holborn offices Wifi

  scope              = "CLOUDFRONT"
  provider           = aws.us-east-1
  ip_address_version = "IPV4"
  description        = "Manual Allow Set for ${local.application_name} WAF"
  addresses          = local.ip_set_list
}

resource "aws_wafv2_ip_set" "wafmanualblockset" {
  name               = "${upper(local.application_name)}-manual-block-set"
  scope              = "CLOUDFRONT"
  provider           = aws.us-east-1
  description        = "Manual Block Set for ${local.application_name} WAF"
  ip_address_version = "IPV4"
  addresses          = []
}

resource "aws_wafv2_rule_group" "manual-rules" {
  name        = "${upper(local.application_name)}-manual-rules"
  provider    = aws.us-east-1
  scope       = "CLOUDFRONT" # Use "CLOUDFRONT" for CloudFront
  capacity    = 10           # Adjust based on complexity
  description = "Manual Allow/Block Rules for ${local.application_name}"

  rule {
    name     = "AllowIPs"
    priority = 1

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.wafmanualallowset.arn
      }
    }

    action {
      allow {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowIPs"
    }
  }

  rule {
    name     = "BlockIPs"
    priority = 2

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.wafmanualblockset.arn
      }
    }

    action {
      block {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockIPs"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "ManualRulesGroup"
  }
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "${upper(local.application_name)}-Whitelisting-Requesters"
  provider    = aws.us-east-1
  scope       = "CLOUDFRONT" # Use "CLOUDFRONT" for CloudFront
  description = "Web ACL for ${local.application_name}"

  default_action {
    block {}
  }

  rule {
    name     = "ManualAllowBlockRules"
    priority = 1

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.manual-rules.arn
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "ManualAllowBlockRules"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${upper(local.application_name)}-Whitelisting-Requesters"
  }
}