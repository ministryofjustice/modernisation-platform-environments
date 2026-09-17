locals {
  global_config = yamldecode(file("${path.module}/../configuration/global.yml"))
  bucket_name   = "${local.global_config.s3_bucket_prefix}-${local.environment}-${local.component_name}"

  cortex_xsiam_workload_identity = local.is-production ? jsondecode(data.aws_secretsmanager_secret_version.cortex_xsiam_workload_identity[0].secret_string) : {
    issuer_url      = ""
    audience        = ""
    service_account = ""
  }
  cortex_xsiam_enabled = local.is-production && local.cortex_xsiam_workload_identity.issuer_url != ""
}
