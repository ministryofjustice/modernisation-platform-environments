module "lambda_upload_ticket" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.resource_name_prefix}-upload-ticket"
  description                  = "Generates presigned S3 upload URLs for managed file transfer clients"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "${local.api_code_root}/lambda/request-upload-ticket"
  trigger_on_package_timestamp = false

  environment_variables = {
    MAX_PRESIGNED_URL_EXPIRY_SECONDS  = tostring(try(local.api_configuration.max_presigned_url_expiry_seconds, 3600))
    MULTIPART_DEFAULT_PART_SIZE_BYTES = tostring(local.multipart_configuration.multipart_default_part_size_bytes)
    MULTIPART_INITIAL_PRESIGN_PARTS   = tostring(local.multipart_configuration.multipart_initial_presign_parts)
    MULTIPART_MAX_PARTS               = tostring(local.multipart_configuration.multipart_max_parts)
    MULTIPART_SESSIONS_TABLE          = module.dynamodb_multipart_uploads.dynamodb_table_id
    PRESIGNED_URL_EXPIRY_SECONDS      = tostring(try(local.api_configuration.presigned_url_expiry_seconds, 900))
    SINGLE_PUT_LIMIT_BYTES            = tostring(local.multipart_configuration.single_put_limit_bytes)
    TRANSFER_CLIENTS_TABLE            = module.dynamodb_transfer_clients.dynamodb_table_id
    UPLOAD_BUCKET_KMS_KEY_ARN         = data.aws_ssm_parameter.mft_upload_bucket_kms_key_arn.value
    UPLOAD_BUCKET_NAME                = data.aws_ssm_parameter.mft_upload_bucket_name.value
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
    multipart_session_table_access = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [
        module.dynamodb_multipart_uploads.dynamodb_table_arn,
      ]
    }
    upload_bucket_write = {
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
      ]
      resources = [
        "${data.aws_ssm_parameter.mft_upload_bucket_arn.value}/*",
      ]
    }
    upload_bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
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

module "lambda_api_authorizer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.resource_name_prefix}-authorizer"
  description                  = "Authenticates and authorises MFT API callers"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "${local.api_code_root}/lambda/request-authorizer"
  trigger_on_package_timestamp = false

  environment_variables = {
    AUTH_PRINCIPALS_TABLE = module.dynamodb_auth_principals.dynamodb_table_id
    AUTH_ROLES_TABLE      = module.dynamodb_auth_roles.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = merge(
    {
      auth_principals_table_read = {
        effect = "Allow"
        actions = [
          "dynamodb:GetItem",
        ]
        resources = [
          module.dynamodb_auth_principals.dynamodb_table_arn,
        ]
      }
      auth_roles_table_read = {
        effect = "Allow"
        actions = [
          "dynamodb:GetItem",
        ]
        resources = [
          module.dynamodb_auth_roles.dynamodb_table_arn,
        ]
      }
    },
    length(local.auth_users) > 0 ? {
      auth_user_secret_read = {
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = [
          for secret in values(module.api_user_credentials_secret) : secret.secret_arn
        ]
      }
    } : {},
    length(local.auth_system_principals) > 0 ? {
      auth_system_secret_read = {
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = [
          for secret in values(module.api_system_bearer_token_secret) : secret.secret_arn
        ]
      }
    } : {}
  )

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

module "lambda_api_docs" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name = "${local.resource_name_prefix}-docs"
  description   = "Serves the protected Swagger UI and OpenAPI contract for the MFT API"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  # Rebuild the package on clean CI runners when the local zip is absent.
  trigger_on_package_timestamp = true
  environment_variables = {
    DOCS_BASIC_AUTH_SECRET_ID = module.api_docs_basic_auth_secret.secret_name
  }
  source_path = [
    "${local.api_code_root}/lambda/request-docs",
    "${local.api_code_root}/openapi.yaml",
  ]

  attach_policy_statements = true
  policy_statements = {
    docs_auth_secret_read = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        module.api_docs_basic_auth_secret.secret_arn,
      ]
    }
  }

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}
