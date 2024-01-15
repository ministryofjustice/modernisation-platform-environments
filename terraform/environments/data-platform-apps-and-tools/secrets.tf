/*

These have been created in code as we do not have permission to "secretsmanager:CreateSecret"

*/

resource "aws_secretsmanager_secret" "openmetadata_entra_id_client_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "openmetadata/entra-id/client-id"
}

resource "aws_secretsmanager_secret" "openmetadata_entra_id_tenant_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "openmetadata/entra-id/tenant-id"
}

resource "aws_secretsmanager_secret" "github_app_arc_app_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "github/arc/app-id"
}

resource "aws_secretsmanager_secret" "github_app_arc_install_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "github/arc/install-id"
}

resource "aws_secretsmanager_secret" "github_app_arc_private_key" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "github/arc/private-key"
}

# Create a new secret in AWS SecretsManager for Gov.UK Notify API key
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "gov-uk-notify/production/api-key"
}

# Email secret for Lambda function
resource "aws_secretsmanager_secret" "email_secret" {
  name = "jml/email"
}
