locals {
  global_config = yamldecode(file("${path.module}/../configuration/global.yml"))
  bucket_name   = "${local.global_config.s3_bucket_prefix}-${local.environment}-${local.component_name}"

  cortex_xsiam_enabled = local.is-production && var.cortex_xsiam_workload_identity != null
}
