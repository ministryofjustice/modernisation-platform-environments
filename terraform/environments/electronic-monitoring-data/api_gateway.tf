module "get_zipped_file_api_api" {
  source          = "./modules/api_step_function"
  api_name        = "get_zipped_file_api"
  api_description = "API to trigger step function that gets a zipped file out of storage"
  api_path        = "execute"
  step_function   = module.get_zipped_file_api
  sfn_type        = "express"
  stages = [
    {
      stage_name             = "test",
      stage_description      = "API Stage for testing",
      burst_limit            = 200,
      rate_limit             = 2000,
      throttling_burst_limit = 200,
      throttling_rate_limit  = 2000

    }
  ]
  schema = {
    type = "object"
    properties = {
      file_name     = { type = "string" }
      zip_file_name = { type = "string" }
    }
    required = ["file_name", "zip_file_name"]
  }
  api_version = "0.1.1"
}

module "ears_sars_api" {
  count               = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  source              = "./modules/api_step_function"
  api_name            = "ears_sars_api"
  api_description     = "Ears and Sars API"
  api_path            = "execute"
  step_function       = module.ears_sars_step_function[0]
  sfn_type            = "standard"
  enable_status_check = true
  stages = [
    {
      stage_name             = "request",
      stage_description      = "API Stage for testing",
      burst_limit            = 20,
      rate_limit             = 200,
      throttling_burst_limit = 20,
      throttling_rate_limit  = 200

    }
  ]
  schema = {
    type = "object"
    properties = {
      legacy_subject_id      = { type = ["string", "integer"] }
      legacy_order_id        = { type = ["string", "integer"] }
      priority               = { type = "string" }
      monitoring_requirement = { type = "string" }
      request_types = {
        type  = "array"
        items = { type = "string" }
      }
      information_requested_from = { type = "string" }
      information_requested_to   = { type = "string" }
    }
    required = [
      "legacy_subject_id",
      "legacy_order_id",
      "priority",
      "monitoring_requirement",
      "request_types",
      "information_requested_from",
      "information_requested_to"
    ]
  }
  api_version = "0.1.1"
}

resource "aws_api_gateway_account" "global_usage" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

# --------------------------------------------------------------------------------
# update_p1_export
# --------------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "update_p1_export" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  name        = "update_p1_export"
  description = "Access to update the P1 Export."

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "update_p1_export_add" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  parent_id   = aws_api_gateway_rest_api.update_p1_export[0].root_resource_id
  path_part   = "add"
}

resource "aws_api_gateway_resource" "update_p1_export_remove" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  parent_id   = aws_api_gateway_rest_api.update_p1_export[0].root_resource_id
  path_part   = "remove"
}

resource "aws_api_gateway_method" "update_p1_export_add_post" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id          = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id          = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.update_p1_export[0].id
  request_models = {
    "application/json" = aws_api_gateway_model.update_p1_export[0].name
  }
}

resource "aws_api_gateway_method" "update_p1_export_remove_post" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id          = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id          = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.update_p1_export[0].id
  request_models = {
    "application/json" = aws_api_gateway_model.update_p1_export[0].name
  }
}

# --------------------------------------------------------
# update_p1_export Validator
# --------------------------------------------------------

resource "aws_api_gateway_request_validator" "update_p1_export" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id                 = aws_api_gateway_rest_api.update_p1_export[0].id
  name                        = "≈RequestValidator"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "update_p1_export" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id  = aws_api_gateway_rest_api.update_p1_export[0].id
  name         = "UpdateP1ExportModel"
  content_type = "application/json"
  schema       = jsonencode(
    {
      type = "object"
      properties = {
        case_numbers = { 
          type = "array"
          items = { type = "integer" }
        }
        run_historic = { type = "boolean" }
      }
      required = ["case_numbers", "run_historic"]
    }
  )
}

resource "aws_api_gateway_integration" "update_p1_export_add_lambda_post" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method = aws_api_gateway_method.update_p1_export_add_post[0].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.update_p1_export[0].lambda_function_invoke_arn
}

resource "aws_api_gateway_integration" "update_p1_export_remove_lambda_post" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method = aws_api_gateway_method.update_p1_export_remove_post[0].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.update_p1_export[0].lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "update_p1_export" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  depends_on = [
    aws_api_gateway_integration.update_p1_export_add_lambda_post[0],
    aws_api_gateway_integration.update_p1_export_remove_lambda_post[0],
  ]

  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
}

resource "aws_api_gateway_stage" "update_p1_export_stage" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  deployment_id = aws_api_gateway_deployment.update_p1_export[0].id
  rest_api_id   = aws_api_gateway_rest_api.update_p1_export[0].id
  stage_name    = "prod"
}
