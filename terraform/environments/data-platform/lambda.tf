module "data_product_docs_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_docs"
  tags                           = local.tags
  description                    = "Lambda for swagger api docs"
  function_name                  = "data_product_docs_${local.environment}"
  role_name                      = "docs_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.create_write_lambda_logs.json
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-docs-lambda-ecr-repo:${local.docs_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*"
    }
  }

}

module "data_product_authorizer_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_authorizer"
  tags                           = local.tags
  description                    = "Lambda for custom API Gateway authorizer"
  role_name                      = "authorizer_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_authorizer_lambda.json
  function_name                  = "data_product_authorizer_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-authorizer-lambda-ecr-repo:${local.authorizer_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, {
    authorizationToken = local.api_auth_token
    api_resource_arn   = "${aws_api_gateway_rest_api.data_platform.execution_arn}/*/*"
  })

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*"
    }
  }

}

module "data_product_get_glue_metadata_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_get_glue_metadata"
  tags                           = local.tags
  description                    = "Lambda to retrieve Glue metadata for a specified table in a database"
  role_name                      = "get_glue_metadata_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_get_glue_metadata_lambda.json
  function_name                  = "data_product_get_glue_metadata_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-get-glue-metadata-lambda-ecr-repo:${local.get_glue_metadata_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.get_glue_metadata.http_method}${aws_api_gateway_resource.get_glue_metadata.path}"
    }
  }

}

module "data_product_landing_to_raw_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_landing_to_raw"
  tags                           = local.tags
  description                    = "Lambda to retrieve Glue metadata for a specified table in a database"
  role_name                      = "landing_to_raw_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.landing_to_raw_lambda_policy.json
  function_name                  = "data_product_landing_to_raw_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-landing-to-raw-lambda-ecr-repo:${local.landing_to_raw_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars)

  allowed_triggers = {

    AllowExecutionFromCloudWatch = {
      action     = "lambda:InvokeFunction"
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.object_created_data_landing.arn
    }
  }

}

module "data_product_presigned_url_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_presigned_url"
  tags                           = local.tags
  description                    = "Lambda to generate a presigned url for uploading data"
  role_name                      = "presigned_url_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
  function_name                  = "data_product_presigned_url_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-presigned-url-lambda-ecr-repo:${local.presigned_url_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars)

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.upload_data_for_data_product_table_name.http_method}${aws_api_gateway_resource.upload_data_for_data_product_table_name.path}"
    }
  }

}

module "data_product_athena_load_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_athena_load"
  tags                           = local.tags
  description                    = "Lambda to load and transform raw data products landing in s3. Creates partitioned parquet tables"
  role_name                      = "athena_load_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.athena_load_lambda_function_policy.json
  function_name                  = "data_product_athena_load_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 100

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-athena-load-lambda-ecr-repo:${local.athena_load_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars, {
    ENVIRONMENT = local.environment
  })

  allowed_triggers = {

    AllowExecutionFromCloudWatch = {
      action     = "lambda:InvokeFunction"
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.object_created_raw_data.arn
    }
  }

}


module "data_product_create_metadata_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_create_metadata"
  tags                           = local.tags
  description                    = "Lambda to create the first version of a json metadata file for a data product"
  role_name                      = "data_product_metadata_lambda_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_create_metadata_lambda.json
  function_name                  = "data_product_create_metadata_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-create-metadata-lambda-ecr-repo:${local.create_metadata_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 128

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars, {
    ENVIRONMENT = local.environment
  })

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.register_data_product.http_method}${aws_api_gateway_resource.register_data_product.path}"
    }
  }

}

module "reload_data_product_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "reload_data_product"
  tags                           = local.tags
  description                    = "Reload the data in a data product from raw history to curated, and recreate the athena tables."
  role_name                      = "reload_data_product_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_reload_data_product_lambda.json
  function_name                  = "reload_data_product_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-reload-data-product-lambda-ecr-repo:${local.reload_data_product_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars, {
    ATHENA_LOAD_LAMBDA = module.data_product_athena_load_lambda.lambda_function_name
  })

}

module "resync_unprocessed_files_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "resync_unprocessed_files"
  tags                           = local.tags
  description                    = "Retrigger the athena load for extraction timestamps in raw history and not in curated data, for one data product"
  role_name                      = "resync_unprocessed_files_role_${local.environment}"
  policy_json_attached           = true
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_resync_unprocessed_files_lambda.json
  function_name                  = "resync_unprocessed_files_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-resync-unprocessed-files-lambda-ecr-repo:${local.resync_unprocessed_files_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars, {
    ATHENA_LOAD_LAMBDA = module.data_product_athena_load_lambda.lambda_function_name
  })

}

module "data_product_create_schema_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_create_schema"
  tags                           = local.tags
  description                    = "Lambda to create the first version of a json schema file for a data product"
  role_name                      = "data_product_schema_lambda_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_create_schema_lambda.json
  policy_json_attached           = true
  function_name                  = "data_product_create_schema_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-create-schema-lambda-ecr-repo:${local.create_schema_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 128

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars)
  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.create_schema_for_data_product_table_name.http_method}${aws_api_gateway_resource.schema_for_data_product_table_name.path}"
    }
  }
}

module "get_schema_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "get_schema"
  tags                           = local.tags
  description                    = "Fetch the schema for a table from S3"
  role_name                      = "get_schema_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_get_schema_lambda.json
  policy_json_attached           = true
  function_name                  = "get_schema_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-get-schema-lambda-ecr-repo:${local.get_schema_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 128

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars)

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.get_schema_for_data_product_table_name.http_method}${aws_api_gateway_resource.schema_for_data_product_table_name.path}"
    }
  }
}

module "data_product_update_metadata_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=a4392c1" # ref for V2.1
  application_name               = "data_product_update_metadata"
  tags                           = local.tags
  description                    = "Fetch the schema for a table from S3"
  role_name                      = "update_metadata_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_update_metadata_lambda.json
  policy_json_attached           = true
  function_name                  = "data_product_update_metadata_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-update-metadata-lambda-ecr-repo:${local.update_metadata_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 128

  environment_variables = merge(local.logger_environment_vars, local.storage_environment_vars)

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.update_data_product.http_method}${aws_api_gateway_resource.data_product_name.path}"
    }
  }
}
