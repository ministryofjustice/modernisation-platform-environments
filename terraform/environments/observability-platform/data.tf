data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = aws_secretsmanager_secret.grafana_api_key.id
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "observability_platform_admins" {
  for_each = toset(["observability-platform", "operations-engineering"])

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

data "aws_secretsmanager_secret" "github_ci_user_environments_repo_pat" {
  provider = aws.modernisation-platform
  name     = "github_ci_user_environments_repo_pat"
}

data "aws_secretsmanager_secret_version" "github_ci_user_environments_repo_pat" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.github_ci_user_environments_repo_pat.id
}