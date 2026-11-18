data "aws_secretsmanager_secret_version" "cloud_platform" {
  secret_id = "cloud-platform/live-1"
}

data "aws_iam_openid_connect_provider" "cloud_platform" {
  url = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform.secret_string)["cluster_oidc"]
}