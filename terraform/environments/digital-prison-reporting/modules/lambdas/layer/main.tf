locals {
  s3_bucket         = var.s3_existing_package != null ? try(var.s3_existing_package.bucket, null) : null
  s3_key            = var.s3_existing_package != null ? try(var.s3_existing_package.key, null) : null
  s3_object_version = var.s3_existing_package != null ? try(var.s3_existing_package.version_id, null) : null
}

resource "aws_lambda_layer_version" "this" {
  count = var.create_layer ? 1 : 0

  layer_name   = var.layer_name
  description  = var.description
  license_info = var.license_info

  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.compatible_architectures
  skip_destroy             = var.layer_skip_destroy

  s3_bucket = var.s3_existing_package.bucket
  s3_key    = var.s3_existing_package.key

  dynamic "s3_object_version" {
    for_each = var.s3_existing_package.version != null ? [var.s3_existing_package.version] : []
    content {
      s3_object_version = s3_object_version.value
    }
  }
}
