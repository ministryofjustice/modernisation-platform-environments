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

  # Google workload identity federation (used by LiteLLM to call Google Gemini Enterprise Agent Platform)
  google_cloud_project_name         = jsondecode(data.aws_secretsmanager_secret_version.google_cloud_ai_gateway.secret_string)["project_name"]
  google_cloud_project_id           = jsondecode(data.aws_secretsmanager_secret_version.google_cloud_ai_gateway.secret_string)["project_id"]
  google_service_account_email      = "ai-gateway@${local.google_cloud_project_name}.iam.gserviceaccount.com"
  google_workload_identity_audience = "//iam.googleapis.com/projects/${local.google_cloud_project_id}/locations/global/workloadIdentityPools/amazon-eks/providers/data-platform"

  # No secret material here; external_account credentials only describe how to exchange the projected token, so a ConfigMap is fine
  google_application_credentials = jsonencode({
    type                              = "external_account"
    audience                          = local.google_workload_identity_audience
    subject_token_type                = "urn:ietf:params:oauth:token-type:jwt"
    token_url                         = "https://sts.googleapis.com/v1/token"
    service_account_impersonation_url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${local.google_service_account_email}:generateAccessToken"
    credential_source = {
      file = "/var/run/secrets/sts.googleapis.com/google-identity-token"
    }
  })
}
