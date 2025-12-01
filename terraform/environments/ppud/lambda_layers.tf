########################################################
# Lambda Layers and other dependencies for the functions
########################################################

# Data Sources for S3 Buckets

data "aws_s3_bucket" "layer_buckets" {
  for_each = {
    for env, bucket_name in {
      development   = "moj-infrastructure-dev"
      preproduction = "moj-infrastructure-uat"
      production    = "moj-infrastructure"
    } : env => bucket_name
    if env == local.environment
  }
  bucket = each.value
}

# Lambda Layers

locals {
  lambda_layers = {
    matplotlib    = "matplotlib_layer.zip"
    boto3         = "boto3_layer.zip"
    pandas        = "pandas_layer.zip"
    xlsxwriter    = "xlsxwriter_layer.zip"
    requests      = "requests_layer.zip"
    beautifulsoup = "beautifulsoup_layer.zip"
  }

  layer_env_buckets = {
    for env in keys(data.aws_s3_bucket.layer_buckets) : env => data.aws_s3_bucket.layer_buckets[env].id
  }
  current_env   = local.environment
  active_layers = local.current_env != null ? local.lambda_layers : {}
}

resource "aws_lambda_layer_version" "lambda_layers" {
  for_each = local.active_layers

  layer_name          = "${each.key}_layer_${local.current_env}"
  description         = "${each.key} layer for python 3.12"
  s3_bucket           = local.layer_env_buckets[local.current_env]
  s3_key              = "lambda/layers/${each.value}"
  compatible_runtimes = ["python3.12"]
}
