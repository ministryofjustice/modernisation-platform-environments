provider "opensearch" {
  url               = "https://${data.aws_opensearch_domain.moj_domain.endpoint}"
  username          = jsondecode(data.aws_secretsmanager_secret_version.opensearch_credentials.secret_string)["username"]
  password          = jsondecode(data.aws_secretsmanager_secret_version.opensearch_credentials.secret_string)["password"]
  sign_aws_requests = false
  healthcheck       = true
}
