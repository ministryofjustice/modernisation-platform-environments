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

resource "aws_lambda_layer_version" "create_athena_table_layer" {
  filename            = local.create_athena_table_layer.layer_zip_path
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
  filename            = local.mojap_metadata.layer_zip_path
  layer_name          = local.mojap_metadata.layer_name
  compatible_runtimes = ["python3.11"]
  source_code_hash    = filesha1(local.mojap_metadata.layer_zip_path)
}