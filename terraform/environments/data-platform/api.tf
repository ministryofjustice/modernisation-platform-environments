
resource "aws_api_gateway_rest_api" "data_platform" {
  name = "data_platform"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.get_glue_metadata,
      aws_api_gateway_resource.docs,
      aws_api_gateway_resource.data_product,
      aws_api_gateway_resource.register_data_product,
      aws_api_gateway_resource.data_product_name,
      aws_api_gateway_resource.data_product_preview,
      aws_api_gateway_resource.data_product_table,
      aws_api_gateway_resource.data_product_table_name,
      aws_api_gateway_resource.upload_data_for_data_product_table_name,
      aws_api_gateway_resource.schema_for_data_product_table_name,
      aws_api_gateway_method.preview_data_from_data_product,
      aws_api_gateway_method.docs,
      aws_api_gateway_method.get_glue_metadata,
      aws_api_gateway_method.register_data_product,
      aws_api_gateway_method.upload_data_for_data_product_table_name,
      aws_api_gateway_method.create_schema_for_data_product_table_name,
      aws_api_gateway_method.get_schema_for_data_product_table_name,
      aws_api_gateway_method.update_data_product,
      aws_api_gateway_method.update_schema_for_data_product_table_name,
      aws_api_gateway_integration.docs_to_lambda,
      aws_api_gateway_integration.upload_data_for_data_product_table_name_to_lambda,
      aws_api_gateway_integration.proxy_to_lambda,
      aws_api_gateway_integration.docs_lambda_root,
      aws_api_gateway_integration.get_glue_metadata,
      aws_api_gateway_integration.register_data_product_to_lambda,
      aws_api_gateway_integration.create_schema_for_data_product_table_name_to_lambda,
      aws_api_gateway_integration.get_schema_for_data_product_table_name_to_lambda,
      aws_api_gateway_integration.update_data_product_to_lambda,
      aws_api_gateway_integration.update_schema_for_data_product_table_name_to_lambda,
      aws_api_gateway_integration.preview_data_from_data_product_lambda,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  stage_name    = local.environment

  depends_on = [aws_api_gateway_account.api_gateway_account]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.data_platform_api.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      requestTime      = "$context.requestTime"
      requestTimeEpoch = "$context.requestTimeEpoch"
      ip               = "$context.identity.sourceIp"
      caller           = "$context.identity.caller"
      user             = "$context.identity.user"
      path             = "$context.path"
      resourcePath     = "$context.resourcePath"
      method           = "$context.httpMethod"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "data_platform_api" {
  name = "data_platform_api"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloud_watch_role.arn
}

resource "aws_api_gateway_method_settings" "api_gateway_log_settings" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  stage_name  = local.environment
  method_path = "*/*"

  settings {
    logging_level = "INFO"
  }
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${local.environment}"
  rest_api_id            = aws_api_gateway_rest_api.data_platform.id
  authorizer_uri         = module.data_product_authorizer_lambda.lambda_function_invoke_arn
  authorizer_credentials = aws_iam_role.authoriser_role.arn
  identity_source        = "method.request.header.authorizationToken"
}

# /data-product resource
resource "aws_api_gateway_resource" "data_product" {
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "data-product"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/register resource
resource "aws_api_gateway_resource" "register_data_product" {
  parent_id   = aws_api_gateway_resource.data_product.id
  path_part   = "register"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/register POST method
resource "aws_api_gateway_method" "register_data_product" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.register_data_product.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# /data-product/register lambda integration
resource "aws_api_gateway_integration" "register_data_product_to_lambda" {
  http_method             = aws_api_gateway_method.register_data_product.http_method
  resource_id             = aws_api_gateway_resource.register_data_product.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_create_metadata_lambda.lambda_function_invoke_arn
}

# /data-product/{data-product-name} resource
resource "aws_api_gateway_resource" "data_product_name" {
  parent_id   = aws_api_gateway_resource.data_product.id
  path_part   = "{data-product-name}"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/{data-product} PUT method
resource "aws_api_gateway_method" "update_data_product" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.data_product_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
  }
}

# PUT /data-product/{data-product-name} lambda integration
resource "aws_api_gateway_integration" "update_data_product_to_lambda" {
  http_method             = aws_api_gateway_method.update_data_product.http_method
  resource_id             = aws_api_gateway_resource.data_product_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_update_metadata_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name"
  }
}


# /data-product/{data-product-name}/table resource
resource "aws_api_gateway_resource" "data_product_table" {
  parent_id   = aws_api_gateway_resource.data_product_name.id
  path_part   = "table"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/{data-product-name}/table/{table-name} resource
resource "aws_api_gateway_resource" "data_product_table_name" {
  parent_id   = aws_api_gateway_resource.data_product_table.id
  path_part   = "{table-name}"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/{data-product-name}/table/{table-name}/upload resource
resource "aws_api_gateway_resource" "upload_data_for_data_product_table_name" {
  parent_id   = aws_api_gateway_resource.data_product_table_name.id
  path_part   = "upload"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/{data-product-name}/table/{table-name}/schema resource
resource "aws_api_gateway_resource" "schema_for_data_product_table_name" {
  parent_id   = aws_api_gateway_resource.data_product_table_name.id
  path_part   = "schema"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

# /data-product/{data-product-name}/table/{table-name}/upload POST method
resource "aws_api_gateway_method" "upload_data_for_data_product_table_name" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.upload_data_for_data_product_table_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name}/upload lambda integration
resource "aws_api_gateway_integration" "upload_data_for_data_product_table_name_to_lambda" {
  http_method             = aws_api_gateway_method.upload_data_for_data_product_table_name.http_method
  resource_id             = aws_api_gateway_resource.upload_data_for_data_product_table_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_presigned_url_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema POST method
resource "aws_api_gateway_method" "create_schema_for_data_product_table_name" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema lambda integration
resource "aws_api_gateway_integration" "create_schema_for_data_product_table_name_to_lambda" {
  http_method             = aws_api_gateway_method.create_schema_for_data_product_table_name.http_method
  resource_id             = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_create_schema_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema GET method
resource "aws_api_gateway_method" "get_schema_for_data_product_table_name" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema lambda integration
resource "aws_api_gateway_integration" "get_schema_for_data_product_table_name_to_lambda" {
  http_method             = aws_api_gateway_method.get_schema_for_data_product_table_name.http_method
  resource_id             = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.get_schema_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema PUT method
resource "aws_api_gateway_method" "update_schema_for_data_product_table_name" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name}/schema lambda integration
resource "aws_api_gateway_integration" "update_schema_for_data_product_table_name_to_lambda" {
  http_method             = aws_api_gateway_method.update_schema_for_data_product_table_name.http_method
  resource_id             = aws_api_gateway_resource.schema_for_data_product_table_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_update_schema_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

# /data-product/{data-product-name}/table/{table-name} DELETE method
resource "aws_api_gateway_method" "delete_table_for_data_product" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.data_product_table_name.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name} (delete table and data) lambda integration
resource "aws_api_gateway_integration" "delete_table_for_data_product_to_lambda" {
  http_method             = aws_api_gateway_method.delete_table_for_data_product.http_method
  resource_id             = aws_api_gateway_resource.data_product_table_name.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.delete_table_for_data_product_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

# API docs endpoint

resource "aws_api_gateway_resource" "docs" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_method" "docs" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_resource.docs.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_to_lambda" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.docs.resource_id
  http_method = aws_api_gateway_method.docs.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  parent_id   = aws_api_gateway_resource.docs.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_to_lambda" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "MOCK"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn

  lifecycle {
    ignore_changes = all
  }
}

# get_glue_metadata endpoint

resource "aws_api_gateway_resource" "get_glue_metadata" {
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "get_glue_metadata"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

resource "aws_api_gateway_method" "get_glue_metadata" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization" = true,
    "method.request.querystring.database" = true,
    "method.request.querystring.table"    = true,
  }
}

resource "aws_api_gateway_integration" "get_glue_metadata" {
  http_method             = aws_api_gateway_method.get_glue_metadata.http_method
  resource_id             = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_get_glue_metadata_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.querystring.database" = "method.request.querystring.database",
    "integration.request.querystring.table"    = "method.request.querystring.table"
  }
}

# Preview data 

# /data-product/{data-product-name}/table/{table-name}/preview resource
resource "aws_api_gateway_resource" "data_product_preview" {
  parent_id   = aws_api_gateway_resource.data_product_table_name.id
  path_part   = "preview"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}


# /data-product/{data-product-name}/table/{table-name}/preview GET method
resource "aws_api_gateway_method" "preview_data_from_data_product" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.data_product_preview.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id

  request_parameters = {
    "method.request.header.Authorization"   = true,
    "method.request.path.data-product-name" = true,
    "method.request.path.table-name"        = true,
  }
}

# /data-product/{data-product-name}/table/{table-name}/preview  lambda integration
resource "aws_api_gateway_integration" "preview_data_from_data_product_lambda" {
  http_method             = aws_api_gateway_method.preview_data_from_data_product.http_method
  resource_id             = aws_api_gateway_resource.data_product_preview.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.preview_data_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.path.data-product-name" = "method.request.path.data-product-name",
    "integration.request.path.table-name"        = "method.request.path.table-name",
  }
}

