data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = aws_secretsmanager_secret.grafana_api_key.id
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "analytical-platform"
    }
  }
}

output "name" {
  value = data.aws_identitystore_group.this.id
}
