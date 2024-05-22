resource "aws_wafv2_ip_set" "moj_whitelist" {
  name               = "${upper(local.application_name_short)}_Whitelist_MOJ"
  description        = "List of Internal MOJ Addresses that are whitelisted. Comments above the relevant IPs shows where they are https://github.com/ministryofjustice/moj-ip-addresses/blob/master/moj-cidr-addresses.yml"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [for ip in split("\n", chomp(file("${path.module}/aws_waf_ipset.txt"))) : ip]
}

# resource "aws_wafv2_web_acl" "cwa" {
#   name     = "${upper(local.application_name_short)}_WebAcl"
#   scope    = "REGIONAL"

#   dynamic "default_action" {
#     for_each = local.environment == "production" ? [1] : []
#     content {
#       allow {}
#     }
#   }

#   dynamic "default_action" {
#     for_each = local.environment != "production" ? [1] : []
#     content {
#       block {}
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${upper(local.application_name_short)}WebRequests"
#     sampled_requests_enabled   = true
#   }

#   rule {
#     name     = "${upper(local.application_name_short)}_Whitelist_MOJ"
#     priority = 4
#     action {
#       allow {}
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "${upper(local.application_name_short)}WhitelistMoJMetric"
#       sampled_requests_enabled   = true
#     }
#     statement {
#       ip_set_reference_statement {
#         arn = aws_wafv2_ip_set.moj_whitelist.arn
#       }
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 0

#     dynamic "override_action" {
#         for_each = local.environment == "production" ? [1] : []
#         content {
#             count {}
#         }
#     }

#     dynamic "override_action" {
#         for_each = local.environment != "production" ? [1] : []
#         content {
#             none {}
#         }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleMetric"
#       sampled_requests_enabled   = true
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"

#         # In the Landing Zone, these rules uses ExcludedRule (which specifies a single rule in a rule group whose action you want to override to Count), however this has been deprecated on Terraform, and AWS documentation advises instead of this option, use RuleActionOverrides. It accepts any valid action setting, including Count.
#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "GenericRFI_QUERYARGUMENTS"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "CrossSiteScripting_BODY"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "CrossSiteScripting_COOKIE"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "SizeRestrictions_BODY"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "GenericRFI_BODY"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "CrossSiteScripting_QUERYARGUMENTS"
#         }

#         rule_action_override {
#           action_to_use {
#             count {}
#           }

#           name = "NoUserAgent_HEADER"
#         }

#       }
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesKnownBadInputsRuleSet"
#     priority = 1

#     dynamic "override_action" {
#         for_each = local.environment == "production" ? [1] : []
#         content {
#             count {}
#         }
#     }

#     dynamic "override_action" {
#         for_each = local.environment != "production" ? [1] : []
#         content {
#             none {}
#         }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesKnownBadInputsRuleMetric"
#       sampled_requests_enabled   = true
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesKnownBadInputsRuleSet"
#         vendor_name = "AWS"
#       }
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesAmazonIpReputationList"
#     priority = 2

#     dynamic "override_action" {
#         for_each = local.environment == "production" ? [1] : []
#         content {
#             count {}
#         }
#     }

#     dynamic "override_action" {
#         for_each = local.environment != "production" ? [1] : []
#         content {
#             none {}
#         }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
#       sampled_requests_enabled   = true
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesAmazonIpReputationList"
#         vendor_name = "AWS"
#       }
#     }
#   }

#   rule {
#     name     = "BlockIfContainsPath"
#     priority = 3

#     action {
#       block {}
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "JSPBlockWAFRule"
#       sampled_requests_enabled   = true
#     }

#     ## Due to a Terraform Bug, the rule required cannot be implemented via Terraform with too many nested blocks - https://github.com/hashicorp/terraform-provider-aws/issues/15580
#     ## Thus a dummy rule is implemented here instead, with the actual rule required stored as json in BlockIfContainsPath.json
#     ## This needs to be updated manually via the AWS Console after the Terraform deployment
#     statement {
#       byte_match_statement {
#           positional_constraint = "CONTAINS"
#           search_string = "/OA_HTML/cabo/jsps/a.jsp"
#           text_transformation {
#               priority = 0
#               type = "NONE"
#           }
#           field_to_match {
#               uri_path {}
#           }
#       }
#     }

#     # statement {
#     #   and_statement {
#     #     statement {
#     #         byte_match_statement {
#     #             positional_constraint = "CONTAINS"
#     #             search_string = "/OA_HTML/cabo/jsps/a.jsp"
#     #             text_transformation {
#     #                 priority = 0
#     #                 type = "NONE"
#     #             }
#     #             field_to_match {
#     #                 uri_path {}
#     #             }
#     #         }
#     #         not_statement {
#     #             statement {
#     #                 or_statement {
#     #                     statement {
#     #                         byte_match_statement {
#     #                             positional_constraint = "CONTAINS"
#     #                             search_string = "redirect=/OA_HTML/OA.jsp"
#     #                             text_transformation {
#     #                                 priority = 0
#     #                                 type = "NONE"
#     #                             }
#     #                             field_to_match {
#     #                                 query_string {}
#     #                             }
#     #                         }
#     #                         and_statement {
#     #                             statement {
#     #                                 byte_match_statement {
#     #                                     positional_constraint = "CONTAINS"
#     #                                     search_string = "2FOA_HTML"
#     #                                     text_transformation {
#     #                                         priority = 0
#     #                                         type = "NONE"
#     #                                     }
#     #                                     field_to_match {
#     #                                         query_string {}
#     #                                     }
#     #                                 }
#     #                                 byte_match_statement {
#     #                                     positional_constraint = "CONTAINS"
#     #                                     search_string = "2FOA.jsp"
#     #                                     text_transformation {
#     #                                         priority = 0
#     #                                         type = "NONE"
#     #                                     }
#     #                                     field_to_match {
#     #                                         query_string {}
#     #                                     }
#     #                                 }
#     #                             }
#     #                         }
#     #                     }
#     #                 }
#     #             }
#     #         }
#     #         byte_match_statement {
#     #             positional_constraint = "CONTAINS"
#     #             search_string = "redirect"
#     #             text_transformation {
#     #                 priority = 0
#     #                 type = "NONE"
#     #             }
#     #             field_to_match {
#     #                 query_string {}
#     #             }
#     #         }
#     #     }

#     #   } 
#     # }
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${upper(local.application_name_short)}_WebAcl"
#     },
#   )
# }

###################################
## AWS CloudFormation workaround
###################################

resource "aws_cloudformation_stack" "wafv2" {
  name = "${local.application_name_short}-wafv2"
  parameters = {
    pEnvironment    = local.environment
    pAppName        = upper(local.application_name_short)
    pIsProd         = local.environment == "production" ? "true" : "false"
    pIPWhiteListArn = aws_wafv2_ip_set.moj_whitelist.arn
  }
  template_body = file("${path.module}/wafv2.template")
}

resource "aws_wafv2_web_acl_association" "cwa" {
  resource_arn = aws_lb.external.arn
  web_acl_arn  = aws_cloudformation_stack.wafv2.outputs["WAFv2ARN"]
}

resource "aws_cloudwatch_log_group" "wafv2" {
  count             = local.environment != "production" ? 1 : 0
  name              = "aws-waf-logs-${local.application_name_short}"
  retention_in_days = 7
  tags = merge(
    local.tags,
    {
      Name = "aws-waf-logs-${local.application_name_short}"
    },
  )

}

resource "aws_wafv2_web_acl_logging_configuration" "non_prod" {
  count                   = local.environment != "production" ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.wafv2[0].arn]
  resource_arn            = aws_cloudformation_stack.wafv2.outputs["WAFv2ARN"]
}

