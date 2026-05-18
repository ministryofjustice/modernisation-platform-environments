data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = "grafana/api-key"
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "observability_platform_admins" {
  for_each = toset(["observability-platform", "operations-engineering", "azure-aws-sso-modernisation-platform"])

  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.value
  }
}

data "aws_identitystore_group" "all_identity_centre_teams" {
  for_each = { for team in local.all_identity_centre_teams : team => team }

  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.value
  }
}

data "aws_secretsmanager_secret_version" "github_app_id" {
  secret_id = "github/data-sources/app-id"
}

data "aws_secretsmanager_secret_version" "github_app_installation_id" {
  secret_id = "github/data-sources/app-installation-id"
}

data "aws_secretsmanager_secret_version" "github_app_private_key" {
  secret_id = "github/data-sources/app-private-key"
}
