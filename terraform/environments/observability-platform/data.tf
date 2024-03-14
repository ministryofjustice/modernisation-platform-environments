data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = aws_secretsmanager_secret.grafana_api_key.id
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "observability_platform" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "GroupId"
    attribute_value = "16a2d234-1031-70b5-2657-7f744c55e48f"
  }
}

output "observability_platform_display_name" {
  value = data.aws_identitystore_group.observability_platform.display_name
}

data "aws_identitystore_group" "analytical_platform" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "GroupId"
    attribute_value = "9c6710dd7f-e2cdaf44-0510-48cd-8bb1-4b21552ae0f1"
  }
}

output "analytical_platform_display_name" {
  value = data.aws_identitystore_group.analytical_platform.display_name
}

data "aws_identitystore_group" "data_platform" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "GroupId"
    attribute_value = "a68242b4-b0a1-7085-25f4-dc60e4c122c0"
  }
}

output "data_platform_display_name" {
  value = data.aws_identitystore_group.data_platform.display_name
}

data "aws_identitystore_group" "dso" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "GroupId"
    attribute_value = "9c6710dd7f-120a1f73-34c1-447a-b34c-6cdc2cd64b5e"
  }
}

output "dso_display_name" {
  value = data.aws_identitystore_group.data_platform.display_name
}