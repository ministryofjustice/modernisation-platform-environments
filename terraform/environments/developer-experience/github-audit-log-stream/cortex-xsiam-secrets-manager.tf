module "cortex_xsiam_workload_identity_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name       = "${local.component_name}/cortex-xsiam-workload-identity"
  kms_key_id = module.kms_key[0].key_arn

  secret_string = jsonencode({
    issuer_url      = "CHANGEME"
    audience        = "CHANGEME"
    service_account = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}