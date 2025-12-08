module "cloud_platform_live_iam_oidc_provider" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=7279fc444aed7e36c60438b46972e1611e48984c" # v6.2.3

  url = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["oidc_provider"]

  tags = merge(
    local.tags,
    {
      "Name" = "cloud-platform-live"
    }
  )
}
