module "api_core" {
  source             = "./modules/api_core"
  environment        = local.environment
  tags               = local.tags
  account_id         = local.account_id
  region             = local.region
  authorizer_version = local.authorizer_version
}

moved {
  from = aws_api_gateway_rest_api.data_platform
  to   = module.api_core.aws_api_gateway_rest_api.data_platform
}

moved {
  from = aws_api_gateway_authorizer.authorizer
  to   = module.api_core.aws_api_gateway_authorizer.authorizer
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = module.api_core.gateway_id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload_data,
      aws_api_gateway_resource.get_glue_metadata,
      aws_api_gateway_resource.docs,
      aws_api_gateway_resource.data_product,
      aws_api_gateway_resource.register_data_product,
      aws_api_gateway_method.upload_data_get,
      aws_api_gateway_method.docs,
      aws_api_gateway_method.get_glue_metadata,
      aws_api_gateway_method.register_data_product,
      aws_api_gateway_integration.docs_to_lambda,
      aws_api_gateway_integration.upload_data_to_lambda,
      aws_api_gateway_integration.proxy_to_lambda,
      aws_api_gateway_integration.docs_lambda_root,
      aws_api_gateway_integration.get_glue_metadata,
      aws_api_gateway_integration.register_data_product_to_lambda
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = module.api_core.gateway_id
  stage_name    = local.environment
}

# /data-product resource
resource "aws_api_gateway_resource" "data_product" {
  parent_id   = module.api_core.root_resource_id
  path_part   = "data-product"
  rest_api_id = module.api_core.gateway_id
}

# /data-product/register resource
resource "aws_api_gateway_resource" "register_data_product" {
  parent_id   = aws_api_gateway_resource.data_product.id
  path_part   = "register"
  rest_api_id = module.api_core.gateway_id
}

# /data-product/register POST method
resource "aws_api_gateway_method" "register_data_product" {
  authorization = "CUSTOM"
  authorizer_id = module.api_core.authorizor_id
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.register_data_product.id
  rest_api_id   = module.api_core.gateway_id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# /data-product/register lambda integration
resource "aws_api_gateway_integration" "register_data_product_to_lambda" {
  http_method             = aws_api_gateway_method.register_data_product.http_method
  resource_id             = aws_api_gateway_resource.register_data_product.id
  rest_api_id             = module.api_core.gateway_id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_create_metadata_lambda.lambda_function_invoke_arn
}

# presigned url API endpoint

resource "aws_api_gateway_resource" "upload_data" {
  parent_id   = module.api_core.root_resource_id
  path_part   = "upload_data"
  rest_api_id = module.api_core.gateway_id
}

resource "aws_api_gateway_method" "upload_data_get" {
  authorization = "CUSTOM"
  authorizer_id = module.api_core.authorizor_id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.upload_data.id
  rest_api_id   = module.api_core.gateway_id

  request_parameters = {
    "method.request.header.Authorization"   = true
    "method.request.querystring.database"   = true,
    "method.request.querystring.table"      = true,
    "method.request.querystring.contentMD5" = true,
  }
}

resource "aws_api_gateway_integration" "upload_data_to_lambda" {
  http_method             = aws_api_gateway_method.upload_data_get.http_method
  resource_id             = aws_api_gateway_resource.upload_data.id
  rest_api_id             = module.api_core.gateway_id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_presigned_url_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.querystring.database"   = "method.request.querystring.database",
    "integration.request.querystring.table"      = "method.request.querystring.table",
    "integration.request.querystring.contentMD5" = "method.request.querystring.contentMD5"
  }
}

# API docs endpoint

resource "aws_api_gateway_resource" "docs" {
  rest_api_id = module.api_core.gateway_id
  parent_id   = module.api_core.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_method" "docs" {
  rest_api_id   = module.api_core.gateway_id
  resource_id   = aws_api_gateway_resource.docs.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_to_lambda" {
  rest_api_id = module.api_core.gateway_id
  resource_id = aws_api_gateway_method.docs.resource_id
  http_method = aws_api_gateway_method.docs.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = module.api_core.gateway_id
  parent_id   = aws_api_gateway_resource.docs.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = module.api_core.gateway_id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_to_lambda" {
  rest_api_id = module.api_core.gateway_id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = module.api_core.gateway_id
  resource_id   = module.api_core.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_lambda_root" {
  rest_api_id = module.api_core.gateway_id
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
  parent_id   = module.api_core.root_resource_id
  path_part   = "get_glue_metadata"
  rest_api_id = module.api_core.gateway_id
}

resource "aws_api_gateway_method" "get_glue_metadata" {
  authorization = "CUSTOM"
  authorizer_id = module.api_core.authorizor_id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id   = module.api_core.gateway_id

  request_parameters = {
    "method.request.header.Authorization" = true,
    "method.request.querystring.database" = true,
    "method.request.querystring.table"    = true,
  }
}

resource "aws_api_gateway_integration" "get_glue_metadata" {
  http_method             = aws_api_gateway_method.get_glue_metadata.http_method
  resource_id             = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id             = module.api_core.gateway_id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_get_glue_metadata_lambda.lambda_function_invoke_arn

  request_parameters = {
    "integration.request.querystring.database" = "method.request.querystring.database",
    "integration.request.querystring.table"    = "method.request.querystring.table"
  }
}
