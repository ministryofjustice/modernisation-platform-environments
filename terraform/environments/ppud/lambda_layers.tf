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
  current_env = local.environment
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

############## Development Environment ##################

# Lambda Layer for Matplotlib

resource "aws_lambda_layer_version" "lambda_layer_matplotlib_dev" {
  count               = local.is-development == true ? 1 : 0
  layer_name          = "matplotlib-layer"
  description         = "matplotlib-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure-dev[0].id
  s3_key              = "lambda/layers/matplotlib-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for requests

resource "aws_lambda_layer_version" "lambda_layer_requests_dev" {
  count               = local.is-development == true ? 1 : 0
  layer_name          = "requests-layer-dev"
  description         = "requests-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure-dev[0].id
  s3_key              = "lambda/layers/requests-layer.zip"
  compatible_runtimes = ["python3.12"]
}

############## Preproduction Environment ###############

# Lambda Layer for Matplotlib

resource "aws_lambda_layer_version" "lambda_layer_matplotlib_uat" {
  count               = local.is-preproduction == true ? 1 : 0
  layer_name          = "matplotlib-layer-uat"
  description         = "matplotlib-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure-uat[0].id
  s3_key              = "lambda/layers/matplotlib-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for requests

resource "aws_lambda_layer_version" "lambda_layer_requests_uat" {
  count               = local.is-preproduction == true ? 1 : 0
  layer_name          = "requests-layer-uat"
  description         = "requests-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure-uat[0].id
  s3_key              = "lambda/layers/requests-layer.zip"
  compatible_runtimes = ["python3.12"]
}

############## Production Environment ##################

# Lambda Layer for Matplotlib

resource "aws_lambda_layer_version" "lambda_layer_matplotlib_prod_new" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "matplotlib-layer-prod"
  description         = "matplotlib-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/matplotlib-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for Boto3

resource "aws_lambda_layer_version" "lambda_layer_boto3_prod" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "boto3-layer"
  description         = "boto3-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/boto3-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for Pandas

resource "aws_lambda_layer_version" "lambda_layer_pandas_prod" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "pandas-layer"
  description         = "pandas-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/pandas-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for Beautifulsoup4

resource "aws_lambda_layer_version" "lambda_layer_beautifulsoup_prod" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "beautifulsoup-layer-prod"
  description         = "beautifulsoup-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/beautifulsoup-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for xlsxwriter

resource "aws_lambda_layer_version" "lambda_layer_xlsxwriter_prod" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "xlsxwriter-layer-prod"
  description         = "xlsxwriter-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/xlsxwriter-layer.zip"
  compatible_runtimes = ["python3.12"]
}

# Lambda Layer for requests

resource "aws_lambda_layer_version" "lambda_layer_requests_prod" {
  count               = local.is-production == true ? 1 : 0
  layer_name          = "requests-layer-prod"
  description         = "requests-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-infrastructure[0].id
  s3_key              = "lambda/layers/requests-layer.zip"
  compatible_runtimes = ["python3.12"]
}