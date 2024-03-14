data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = aws_secretsmanager_secret.grafana_api_key.id
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  # This fails with the following error:
  #   Error: reading AWS SSO Identity Store Group Data Source (d-XXXXXX): operation error identitystore: GetGroupId, https response error StatusCode: 400, RequestID: 059df12d-84ce-4803-9a6b-0d41624d749f, ResourceNotFoundException: Group not found
  # alternate_identifier {
  #   unique_attribute {
  #     attribute_path  = "DisplayName"
  #     attribute_value = "analytical-platform"
  #   }
  # }

  # This is deprecated, but @dms1981 said it works...
  filter {
    attribute_path  = "DisplayName"
    attribute_value = "analytical-platform"
  }
}

output "name" {
  value = data.aws_identitystore_group.this.id
}
