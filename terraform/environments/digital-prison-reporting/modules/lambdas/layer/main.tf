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

  compatible_runtimes      = length(var.compatible_runtimes) > 0 ? var.compatible_runtimes : [var.runtime]
  compatible_architectures = var.compatible_architectures
  skip_destroy             = var.layer_skip_destroy

  filename         = "${path.module}/manifests/${var.local_file}"
  source_code_hash = filebase64sha256("${path.module}/manifests/${var.local_file}")

  s3_bucket         = local.s3_bucket
  s3_key            = local.s3_key
  s3_object_version = local.s3_object_version
}
