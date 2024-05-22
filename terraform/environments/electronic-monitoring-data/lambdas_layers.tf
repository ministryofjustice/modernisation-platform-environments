# --------------------------------------------------------------------------------------------------
# create_external_athena_tables layer
# --------------------------------------------------------------------------------------------------
locals {
  layer_path        = "${local.lambda_path}/layers"
  layer_zip_name    = "create_athena_external_tables_layer.zip"
  layer_name        = "create_athena_external_tables_layer"
  requirements_name = "create_athena_external_tables_requirements.txt"
  requirements_path = "${local.layer_path}/${local.requirements_name}"
  layer_zip_path    = "${local.layer_path}/${local.layer_zip_name}"
}

resource "aws_lambda_layer_version" "create_external_athena_tables_layer" {
    filename            = local.layer_zip_path
    layer_name          = local.layer_name
    compatible_runtimes = ["python3.11"]
    source_code_hash = filesha1(local.layer_zip_path)
}

# --------------------------------------------------------------------------------------------------
# mojap_metadata layer
# --------------------------------------------------------------------------------------------------
locals {
  mojap_metadata = {
    layer_zip_name    = "mojap_metadata.zip"
    layer_name        = "mojap_metadata"
    requirements_name = "mojap_metadata_requirements.txt"
    requirements_path = "${local.layer_path}/${local.requirements_name}"
    layer_zip_path    = "${local.layer_path}/${local.layer_zip_name}"
  }
}

resource "aws_lambda_layer_version" "mojap_metadata_layer" {
    filename            = local.mojap_metadata.layer_zip_path
    layer_name          = local.mojap_metadata.layer_name
    compatible_runtimes = ["python3.11"]
    # source_code_hash = filesha1(local.mojap_metadata.layer_zip_path)
}