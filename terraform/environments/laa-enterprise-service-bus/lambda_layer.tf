#####################################################################################
##################    Lambda Layer Artifact (from S3, not uploaded)    #############
#####################################################################################
data "aws_s3_object" "lambda_layer_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "layers_files/lambda_dependencies.zip"
}

#####################################################################################
### Create the Lambda layer for Oracle Python ###
#####################################################################################

resource "aws_lambda_layer_version" "lambda_layer_oracle_python" {
  layer_name          = "cwa-extract-oracle-python"
  description         = "Oracle DB layer for Python"
  s3_bucket           = data.aws_s3_object.lambda_layer_zip.bucket
  s3_key              = data.aws_s3_object.lambda_layer_zip.key
  s3_object_version   = data.aws_s3_object.lambda_layer_zip.version_id
  compatible_runtimes = ["python3.10"]
}