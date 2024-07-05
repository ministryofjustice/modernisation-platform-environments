# resource "aws_waf_ipset" "wafmanualallowset" {
#   name     = "${upper(local.application_name)} Manual Allow Set"
#   # description        = ""
#   # scope              = "CLOUDFRONT"
#   provider           = aws.us-east-1
#   # ip_address_version = "IPV4"
#   addresses          = [for ip in split("\n", chomp(file("${path}/aws_waf_ipset.txt"))) : ip]
# }

locals {
  ip_set_list = [for ip in split("\n", chomp(file("${path.module}/aws_waf_ipset.txt"))) : ip]
}

resource "aws_waf_ipset" "wafmanualallowset" {
  name = "${upper(local.application_name)} Manual Allow Set"

  # Ranges from https://github.com/ministryofjustice/laa-apex/blob/master/aws/application/application_stack.template
  # removed redundant ip addresses such as RedCentric access and AWS Holborn offices Wifi

  dynamic "ip_set_descriptors" {
    for_each = local.ip_set_list
    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_ipset" "wafmanualblockset" {
  name = "${upper(local.application_name)} Manual Block Set"
}

resource "aws_waf_rule" "wafmanualallowrule" {
  depends_on  = [aws_waf_ipset.wafmanualallowset]
  name        = "${upper(local.application_name)} Manual Allow Rule"
  metric_name = "${upper(local.application_name)}ManualAllowRule"

  predicates {
    data_id = aws_waf_ipset.wafmanualallowset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_rule" "wafmanualblockrule" {
  depends_on  = [aws_waf_ipset.wafmanualblockset]
  name        = "${upper(local.application_name)} Manual Block Rule"
  metric_name = "${upper(local.application_name)}ManualBlockRule"

  predicates {
    data_id = aws_waf_ipset.wafmanualblockset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "waf_acl" {
  depends_on = [
    aws_waf_rule.wafmanualallowrule,
    aws_waf_rule.wafmanualblockrule,
  ]
  name        = "${upper(local.application_name)} Whitelisting Requesters"
  metric_name = "${upper(local.application_name)}WhitelistingRequesters"
  #   scope    = "CLOUDFRONT"
  #   provider = aws.us-east-1
  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }
    priority = 1
    rule_id  = aws_waf_rule.wafmanualallowrule.id
    type     = "REGULAR"
  }

  rules {
    action {
      type = "BLOCK"
    }
    priority = 2
    rule_id  = aws_waf_rule.wafmanualblockrule.id
    type     = "REGULAR"
  }
}









