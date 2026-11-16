module "cloud_platform_live_iam_oidc_provider" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=d6e381ccfa95b944149c8b14ba4087e517c57ac7" # v6.8.0

  url = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live.secret_string)["oidc_provider"]

  tags = merge(
    local.tags,
    {
      "Name" = "cloud-platform-live"
    }
  )
}

module "justiceuk_entra_iam_oidc_provider" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=d6e381ccfa95b944149c8b14ba4087e517c57ac7" # v6.8.0

  url = "https://sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra.secret_string)["tenant_id"]}/"
  client_id_list = distinct(concat(
    ["sts.amazonaws.com"],
    try(values(tomap(jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra.secret_string)["client_id_map"])), [])
  ))

  tags = merge(
    local.tags,
    {
      "Name" = "justiceuk-entra"
    }
  )
}
