data "aws_subnet" "private_subnet_ids" {
  for_each = toset(data.aws_subnets.shared-private.ids)
  id       = each.value
}

data "aws_opensearch_domain" "moj_domain" {
  domain_name = "streaming-pov-opensearch"
}

data "aws_secretsmanager_secret" "opensearch_credentials" {
  name = "streaming-pov-opensearch/master-credentials"
}

data "aws_secretsmanager_secret_version" "opensearch_credentials" {
  secret_id = data.aws_secretsmanager_secret.opensearch_credentials.id
}
