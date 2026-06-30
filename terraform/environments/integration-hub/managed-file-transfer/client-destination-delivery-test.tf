module "lambda_products_poc_destination_presign_api" {
  count = local.environment == "development" ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.application_name}-products-poc-destination-presign-api"
  architectures                = ["arm64"]
  description                  = "Development-only mock consumer API that returns a presigned destination upload URL for products-poc"
  handler                      = "lambda_function.lambda_handler"
  memory_size                  = 256
  runtime                      = "python3.12"
  source_path                  = "lambda/mock-destination-presign-api"
  timeout                      = 10
  trigger_on_package_timestamp = false

  environment_variables = {
    DESTINATION_BUCKET_NAME = module.s3_bucket["investigation"].s3_bucket_id
    DESTINATION_KMS_KEY_ARN = module.kms_s3_bucket["investigation"].key_arn
    DESTINATION_PREFIX      = "manual-destination-tests"
  }

  attach_policy_statements = true
  policy_statements = {
    destination_bucket_write = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
      ]
      resources = [
        "${module.s3_bucket["investigation"].s3_bucket_arn}/manual-destination-tests/*",
      ]
    }
    destination_bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
      ]
      resources = [
        module.kms_s3_bucket["investigation"].key_arn,
      ]
    }
  }

  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

resource "aws_lambda_function_url" "products_poc_destination_presign_api" {
  count = local.environment == "development" ? 1 : 0

  function_name      = module.lambda_products_poc_destination_presign_api[0].lambda_function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "products_poc_destination_presign_api_url" {
  count = local.environment == "development" ? 1 : 0

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = module.lambda_products_poc_destination_presign_api[0].lambda_function_name
  function_url_auth_type = "NONE"
  principal              = "*"
  statement_id           = "AllowPublicInvokeFunctionUrl"
}
