data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = "grafana/api-key"
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_groups" "all" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

locals {
  identitystore_group_ids_by_name = {
    for group in data.aws_identitystore_groups.all.groups :
    group.display_name => group.group_id
  }
}

data "aws_secretsmanager_secret_version" "github_app_id" {
  secret_id = "grafana/data-sources/github-app-id"
}

data "aws_secretsmanager_secret_version" "github_app_installation_id" {
  secret_id = "grafana/data-sources/github-app-installation-id"
}

data "aws_secretsmanager_secret_version" "github_app_private_key" {
  secret_id = "grafana/data-sources/github-app-private-key"
}
