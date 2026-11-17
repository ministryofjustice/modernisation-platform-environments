module "cloud_platform_live_iam_oidc_provider" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=82afc6ce4a44b5e97ad00c10d7909c887078f07d" # v6.11.0

  url = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_1.secret_string)["cluster_oidc"]

  tags = merge(
    local.tags,
    {
      "Name" = "cloud-platform-live-1"
    }
  )
}
