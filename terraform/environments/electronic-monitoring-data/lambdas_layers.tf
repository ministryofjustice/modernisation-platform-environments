# --------------------------------------------------------------------------------------------------
# create_external_athena_tables layer
# --------------------------------------------------------------------------------------------------
locals {
  layer_path        = "${local.lambda_path}/layers"
  layer_zip_name    = "create_athena_external_tables_layer.zip"
  layer_name        = "create_athena_external_tables_layer"
  requirements_name = "create_athena_external_tables_requirements.txt"
  requirements_path = "${local.layer_path}/${local.requirements_name}"
  layer_zip_path    = "${local.lambda_path}/${local.layer_zip_name}"
}

resource "null_resource" "lambda_layer" {
  triggers = {
    requirements = filesha1(local.requirements_path)
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${local.layer_path}
      rm -rf python
      mkdir python
      pip3 install -r ${local.requirements_name} -t python/
      zip -m -r ${local.layer_zip_name} python/
    EOT
  }
}

resource "aws_lambda_layer_version" "create_external_athena_tables_layer" {
    filename            = local.layer_zip_name
    layer_name          = local.layer_name
    compatible_runtimes = ["python3.12"]
    source_code_hash    = filesha1(local.layer_zip_name)
}