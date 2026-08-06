module "cloud_platform_live_iam_oidc_provider" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  url = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live.secret_string)["oidc_provider"]

  tags = merge(
    local.tags,
    {
      "Name" = "cloud-platform-live"
    }
  )
}

module "justiceuk_entra_iam_oidc_provider" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  url = "https://sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra.secret_string)["tenant_id"]}/"

  tags = merge(
    local.tags,
    {
      "Name" = "justiceuk-entra"
    }
  )
}
