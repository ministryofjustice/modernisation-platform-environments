module "iam_oidc_provider" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  url            = "https://oidc-configuration.audit-log.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(
    local.tags,
    {
      "Name" = local.component_name
    }
  )
}

resource "aws_iam_openid_connect_provider" "cortex_xsiam" {
  count = local.cortex_xsiam_enabled ? 1 : 0

  url            = local.cortex_xsiam_workload_identity.issuer_url
  client_id_list = [local.cortex_xsiam_workload_identity.audience]
}
