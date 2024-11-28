
##
# SSM Parameters for LDAP
##

locals {
  ldap_ssm = {
    vars = [
      "aptracker_user",
      "casenotes_user",
      "dss_user",
      "iaps_user",
      "oasys_user"
    ]
    secrets = [
      "aptracker_password",
      "casenotes_password",
      "dss_user_password",
      "iaps_user_password",
      "ldap_admin_password",
      "oasys_user_password",
      "performance_test_user_password",
      "test_user_password"
    ]
  }
}

module "ldap_ssm" {
  source           = "../helpers/ssm_params"
  application_name = "ldap"
  environment_name = "${var.account_info.application_name}-${var.env_name}"
  params_plain     = local.ldap_ssm.vars
  params_secure    = local.ldap_ssm.secrets
}

data "aws_ssm_parameter" "ldap_ssm" {
  count = length(module.ldap_ssm.param_names) > 0 ? 1 : 0 # ensures it doesn't try retrieve values until the module creates all params
  for_each = toset(local.ldap_ssm.vars)
  name     = "/${var.account_info.application_name}-${var.env_name}/ldap/${each.key}"
}

