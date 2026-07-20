locals {
  environment_configuration = local.environment_configurations[local.environment]
  litellm_master_key        = "sk-${random_password.litellm_secret_key.result}" # "sk-" prefix is required by LiteLLM
  ai_gateway_models         = yamldecode(file("${path.module}/configuration/models.yml"))
  has_reader                = contains(keys(local.environment_configuration.aurora_instances), "reader")
  # checkov:skip=CKV_SECRET_6: Dummy placeholder for IAM auth flow, not a real secret
  dummy_password = "iam-auth-dummy-password"
  proxy_admin_emails = [
    "Muhammad.Ahmad@justice.gov.uk",
    "Jeremy.Collins@justice.gov.uk",
    "Gary.Henderson1@justice.gov.uk",
    "Lauren.Taylor-Brown@justice.gov.uk",
    "Jacob.Woffenden@justice.gov.uk"
  ]
}
