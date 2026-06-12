module "lambda_upload_ticket" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.application_name}-${local.component_name}-upload-ticket"
  description                  = "Generates presigned S3 upload URLs for managed file transfer clients"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "${path.module}/lambda/request-upload-ticket"
  trigger_on_package_timestamp = false

  environment_variables = {
    MAX_PRESIGNED_URL_EXPIRY_SECONDS = tostring(try(local.api_configuration.max_presigned_url_expiry_seconds, 3600))
    PRESIGNED_URL_EXPIRY_SECONDS     = tostring(try(local.api_configuration.presigned_url_expiry_seconds, 900))
    TRANSFER_CLIENTS_TABLE           = module.dynamodb_transfer_clients.dynamodb_table_id
    UPLOAD_BUCKET_KMS_KEY_ARN        = data.aws_ssm_parameter.mft_upload_bucket_kms_key_arn.value
    UPLOAD_BUCKET_NAME               = data.aws_ssm_parameter.mft_upload_bucket_name.value
  }

  attach_policy_statements = true
  policy_statements = {
    transfer_client_table_read = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
      ]
      resources = [
        module.dynamodb_transfer_clients.dynamodb_table_arn,
      ]
    }
    upload_bucket_write = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
      ]
      resources = [
        "${data.aws_ssm_parameter.mft_upload_bucket_arn.value}/*",
      ]
    }
    upload_bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
      ]
      resources = [
        data.aws_ssm_parameter.mft_upload_bucket_kms_key_arn.value,
      ]
    }
  }

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}
