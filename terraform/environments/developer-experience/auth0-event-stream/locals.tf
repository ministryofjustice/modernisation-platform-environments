locals {
  global_config = yamldecode(file("${path.module}/../configuration/global.yml"))

  auth0_event_source_name = "aws.partner/auth0.com/operations-engineering-855d764e-dfd4-47d0-8220-db395f5e9815/auth0.logs"
  bucket_name             = "${local.global_config.s3_bucket_prefix}-${local.environment}-${local.component_name}"
}
