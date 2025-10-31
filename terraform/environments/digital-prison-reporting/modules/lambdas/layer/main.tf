locals {
  s3_bucket         = var.s3_existing_package.bucket
  s3_key            = var.s3_existing_package.key
  s3_object_version = contains(keys(var.s3_existing_package), "version_id") ? var.s3_existing_package.version_id : null
}

resource "aws_lambda_layer_version" "this" {
  count = var.create_layer ? 1 : 0

  layer_name   = var.layer_name
  description  = var.description
  license_info = var.license_info

  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.compatible_architectures
  skip_destroy             = var.layer_skip_destroy

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_key

  # Directly assign `s3_object_version` conditionally
  s3_object_version = local.s3_object_version != null ? local.s3_object_version : null
}
