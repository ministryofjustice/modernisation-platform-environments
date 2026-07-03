locals {
  environment_configuration = local.environment_configurations[local.environment]
  ai_gateway_models         = yamldecode(file("${path.module}/configuration/models.yml"))
  has_reader                = contains(keys(local.environment_configuration.aurora_instances), "reader")
  dummy_password            = "iam-auth-dummy-password"
  proxy_admin_emails = [
    "Muhammad.Ahmad@justice.gov.uk",
    "Jeremy.Collins@justice.gov.uk",
    "Gary.Henderson1@justice.gov.uk",
    "Lauren.Taylor-Brown@justice.gov.uk",
    "Jacob.Woffenden@justice.gov.uk"
  ]
}
