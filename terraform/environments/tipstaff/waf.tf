# resource "aws_wafv2_web_acl" "tipstaff_web_acl" {
#   name  = "tipstaff-web-acl"
#   scope = "REGIONAL"

#   default_action {
#     allow {}
#   }

#   rule {
#     name     = "common-rule-set"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleSetMetrics"
#       sampled_requests_enabled   = true
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "tipstaff-web-acl"
#     sampled_requests_enabled   = true
#   }
# }
