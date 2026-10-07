module "transfer_web_app_identity_configuration" {
  source = "./modules/transfer-web-app-identity-configuration"
}

data "aws_ssoadmin_instances" "this" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  for_each          = local.transfer_iam_identity_center_groups
  provider          = aws.sso-readonly
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  group_id          = each.value
}

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
  transfer_iam_identity_center_groups = module.transfer_web_app_identity_configuration.groups
}