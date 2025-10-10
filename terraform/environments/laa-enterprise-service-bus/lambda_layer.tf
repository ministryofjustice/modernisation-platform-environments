#####################################################################################
### Create the Lambda layer for Oracle Python ###
#####################################################################################

resource "aws_lambda_layer_version" "lambda_layer_oracle_python" {
  layer_name          = "cwa-extract-oracle-python"
  description         = "Oracle DB layer for Python"
  s3_bucket           = aws_s3_object.lambda_layer_zip.bucket
  s3_key              = aws_s3_object.lambda_layer_zip.key
  s3_object_version   = aws_s3_object.lambda_layer_zip.version_id
  source_code_hash    = filebase64sha256("layers/lambda_dependencies.zip")
  compatible_runtimes = ["python3.10"]
}

# resource "aws_lambda_layer_version" "oracledb_lambda_layer_python" {
#   count               = local.environment == "test" ? 1 : 0
#   layer_name          = "oracledb-cwa-extract-oracle-python"
#   description         = "Oracle DB layer for Python"
#   s3_bucket           = aws_s3_object.oracledb_lambda_layer_zip[0].bucket
#   s3_key              = aws_s3_object.oracledb_lambda_layer_zip[0].key
#   s3_object_version   = aws_s3_object.oracledb_lambda_layer_zip[0].version_id
#   source_code_hash    = filebase64sha256("layers/oracledb_lambda_dependencies.zip")
#   compatible_runtimes = ["python3.10"]
# }