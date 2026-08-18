locals {
  environment_configuration = local.environment_configurations[local.environment]

  litellm_master_key = "sk-${random_password.litellm_secret_key.result}" # "sk-" prefix is required by LiteLLM
  proxy_admin_emails = [
    "Muhammad.Ahmad@justice.gov.uk",
    "Jeremy.Collins@justice.gov.uk",
    "Gary.Henderson1@justice.gov.uk",
    "Lauren.Taylor-Brown@justice.gov.uk",
    "Jacob.Woffenden@justice.gov.uk"
  ]

  ai_gateway_configuration = yamldecode(file("${path.module}/configuration/configuration.yml"))

  # Models are global in configuration.yml; filter by environment when a model opts in with environments_available.
  # If environments_available is omitted, the model is available in all environments.
  ai_gateway_models = try(local.ai_gateway_configuration.models, {})
  ai_gateway_models_filtered = {
    for provider, models in local.ai_gateway_models :
    provider => {
      for model_key, model in try(models, {}) :
      model_key => model
      if length(try(model.environments_available, [])) == 0 || contains(try(model.environments_available, []), local.environment)
    }
  }

  # RDS
  has_reader = contains(keys(local.environment_configuration.aurora_instances), "reader")
  # checkov:skip=CKV_SECRET_6: Dummy placeholder for IAM auth flow, not a real secret
  dummy_password = "iam-auth-dummy-password"
}
