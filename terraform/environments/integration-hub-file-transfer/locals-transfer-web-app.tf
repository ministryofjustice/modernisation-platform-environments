locals {
  transfer_web_app_log_groups = {
    cloudfront = "${local.application_name}-${local.environment}-web-access"
    waf        = "aws-waf-logs-${local.application_name}-${local.environment}-web"
  }

  transfer_web_app_managed_rules = {
    AWSManagedRulesCommonRuleSet         = 1
    AWSManagedRulesKnownBadInputsRuleSet = 2
  }

  # GetGroupId does not reliably resolve groups by display name, so IDs are explicit here.
  transfer_iam_identity_center_groups = {
    azure-aws-sso-integration-hub = "1622e2b4-9011-7000-b2fc-87228b7308cd"
  }
}