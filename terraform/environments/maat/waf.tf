# locals {
#     ip_set_list   = [for ip in split("\n", chomp(file("${path.module}/waf_ip_set.txt"))) : ip]
# }

# resource "aws_waf_ipset" "allow" {
#   name = "${upper(var.application_name)} Manual Allow Set"

#   # Ranges from https://github.com/ministryofjustice/moj-ip-addresses/blob/master/moj-cidr-addresses.yml
#   # disc_internet_pipeline, disc_dom1, moj_digital_wifi, petty_france_office365, petty_france_wifi, ark_internet, gateway_proxies

#   dynamic "ip_set_descriptors" {
#     for_each = local.ip_set_list
#     content {
#       type  = "IPV4"
#       value = ip_set_descriptors.value
#     }
#   }
# }

# resource "aws_waf_ipset" "block" {
#   name = "${upper(var.application_name)} Manual Block Set"
# }

# resource "aws_waf_rule" "allow" {
#   name        = "${upper(var.application_name)} Manual Allow Rule"
#   metric_name = "${upper(var.application_name)}ManualAllowRule"

#   predicates {
#     data_id = aws_waf_ipset.allow.id
#     negated = false
#     type    = "IPMatch"
#   }
# }

# resource "aws_waf_rule" "block" {
#   name        = "${upper(var.application_name)} Manual Block Rule"
#   metric_name = "${upper(var.application_name)}ManualBlockRule"

#   predicates {
#     data_id = aws_waf_ipset.block.id
#     negated = false
#     type    = "IPMatch"
#   }
# }

# resource "aws_waf_web_acl" "waf_acl" {
#   name        = "${upper(var.application_name)} Whitelisting Requesters"
#   metric_name = "${upper(var.application_name)}WhitelistingRequesters"
#   default_action {
#     type = var.waf_default_action
#   }
#   rules {
#     action {
#       type = "ALLOW"
#     }
#     priority = 1
#     rule_id  = aws_waf_rule.allow.id
#   }
#   rules {
#     action {
#       type = "BLOCK"
#     }
#     priority = 2
#     rule_id  = aws_waf_rule.block.id
#   }
# }