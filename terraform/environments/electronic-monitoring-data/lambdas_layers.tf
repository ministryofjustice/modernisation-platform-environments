# --------------------------------------------------------------------------------------------------
# create_athena_table layer
# --------------------------------------------------------------------------------------------------
locals {
  layer_path = "${local.lambda_path}/layers"
  create_athena_table_layer_core = {
    layer_zip_name    = "create_athena_table_layer.zip"
    layer_name        = "create_athena_table_layer"
    requirements_name = "create_athena_table_requirements.txt"
  }
  create_athena_table_layer = {
    layer_zip_name    = local.create_athena_table_layer_core.layer_zip_name
    layer_name        = local.create_athena_table_layer_core.layer_name
    requirements_name = local.create_athena_table_layer_core.requirements_name
    requirements_path = "${local.layer_path}/${local.create_athena_table_layer_core.requirements_name}"
    layer_zip_path    = "${local.layer_path}/${local.create_athena_table_layer_core.layer_zip_name}"
  }
}

resource "null_resource" "create_athena_table_layer_zip" {
  provisioner "local-exec" {
    command = <<EOT
      pip install -r ${local.create_athena_table_layer.requirements_path} -t python
      zip -r ${local.create_athena_table_layer.layer_zip_path} python
      aws s3 cp ${local.create_athena_table_layer.layer_zip_path} s3://${module.s3_lambda_layer_bucket.bucket}/${local.create_athena_table_layer.layer_zip_name}
    EOT
    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    requirements_hash = filesha256(local.create_athena_table_layer.requirements_path)
  }
}

resource "aws_lambda_layer_version" "create_athena_table_layer" {
  s3_bucket           = module.s3-lambda-layer-bucket.bucket
  s3_key              = var.local.create_athena_table_layer.layer_zip_name
  layer_name          = local.create_athena_table_layer.layer_name
  compatible_runtimes = ["python3.11"]
  source_code_hash    = filesha1(local.create_athena_table_layer.layer_zip_path)
}

# --------------------------------------------------------------------------------------------------
# mojap_metadata layer
# --------------------------------------------------------------------------------------------------
locals {
  mojap_metadata_core = {
    layer_zip_name    = "mojap_metadata.zip"
    layer_name        = "mojap_metadata"
    requirements_name = "mojap_metadata_requirements.txt"
  }

  mojap_metadata = {
    layer_zip_name    = local.mojap_metadata_core.layer_zip_name
    layer_name        = local.mojap_metadata_core.layer_name
    requirements_name = local.mojap_metadata_core.requirements_name
    requirements_path = "${local.layer_path}/${local.mojap_metadata_core.requirements_name}"
    layer_zip_path    = "${local.layer_path}/${local.mojap_metadata_core.layer_zip_name}"
  }
}

resource "aws_lambda_layer_version" "mojap_metadata_layer" {
  s3_bucket           = module.s3-lambda-layer-bucket.bucket
  s3_key              = local.mojap_metadata.layer_zip_name
  layer_name          = local.mojap_metadata.layer_name
  compatible_runtimes = ["python3.11"]
  source_code_hash    = filesha1(local.mojap_metadata.layer_zip_path)
}

resource "null_resource" "mojap_metadata_layer_zip" {
  provisioner "local-exec" {
    command = <<EOT
      pip install -r ${local.mojap_metadata_layer.requirements_path} -t python
      zip -r ${local.mojap_metadata_layer.layer_zip_path} python
      aws s3 cp ${local.mojap_metadata_layer.layer_zip_path} s3://${module.s3_lambda_layer_bucket.bucket}/${local.create_athena_table_layer.layer_zip_name}
    EOT
    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    requirements_hash = filesha256(local.mojap_metadata_layer.requirements_path)
  }
}
