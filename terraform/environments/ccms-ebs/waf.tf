# WAF FOR EBS APP

resource "aws_wafv2_ip_set" "ebs_waf_ip_set" {
  name        = "ebs_waf_ip_set"
  scope       = "REGIONAL"
  description = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "51.149.249.32/27",
    "81.134.202.29/32",
    "35.177.145.193/32",
    "35.176.127.232/32",
    "18.130.39.94/32",
    "51.149.249.0/27",
    "51.149.250.0/24"
  ]

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp-ip-set", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ebs_web_acl" {
  name        = "ebs_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for EBS"

  default_action {
    block {}
  }

  rules {
    name = "ebs-trusted-rule"

    priority          = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ebs_waf_ip_set.arn
      }
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp-web-acl", local.application_name, local.environment)) }
  )
}
