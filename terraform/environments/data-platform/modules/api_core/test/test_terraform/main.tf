// Use the environment to give resources unique names between test runs
variable "environment" {
  type = string
}

module "api_core" {
  source             = "../../"
  tags               = {}
  account_id         = "684969100054"
  region             = "eu-west-2"
  authorizer_version = "1.0.0"
  environment        = var.environment
}


// Now set up a mocked GET method on the root resource
// So that we have something to send test requests to
resource "aws_api_gateway_method" "api_get" {
  authorization = "CUSTOM"
  authorizer_id = module.api_core.authorizor_id
  http_method   = "GET"
  resource_id   = module.api_core.root_resource_id
  rest_api_id   = module.api_core.gateway_id

  request_parameters = {
    "method.request.header.authorizationToken" = true
  }
}

resource "aws_api_gateway_integration" "api_get_mock" {
  http_method             = aws_api_gateway_method.api_get.http_method
  resource_id             = module.api_core.root_resource_id
  rest_api_id             = module.api_core.gateway_id
  integration_http_method = "GET"
  type                    = "MOCK"
  request_templates = {
    "application/json" = <<REQUEST_TEMPLATE
    {
      "statusCode": 200
    }
    REQUEST_TEMPLATE
  }
}

resource "aws_api_gateway_integration_response" "api_get_mock" {
  rest_api_id = aws_api_gateway_integration.api_get_mock.rest_api_id
  resource_id = aws_api_gateway_integration.api_get_mock.resource_id
  http_method = aws_api_gateway_integration.api_get_mock.http_method
  status_code = 200
  response_templates = {
    "application/json" = <<RESPONSE_TEMPLATE
    {
        "message": "hello world"
    }
    RESPONSE_TEMPLATE
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = module.api_core.gateway_id
  resource_id = module.api_core.root_resource_id
  http_method = aws_api_gateway_method.api_get.http_method
  status_code = "200"
}

// Deploy to the "test" stage
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = module.api_core.gateway_id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.api_get_mock))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = module.api_core.gateway_id
  stage_name    = "test"
}
