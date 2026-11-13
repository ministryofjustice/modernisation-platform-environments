locals {
  camel_case_route_name = join(
    "",
    [
      for word in split("_", replace(var.route_name, "-", "_")) :
      title(word)
    ]
  )
  sync         = lower(var.sfn_type) == "express" ? "Sync" : ""
  sfn_arn_type = lower(var.sfn_type) == "express" ? "express" : "execution"
  express_response = <<EOF_RESPONSE
#set ($parsedPayload = $util.parseJson($input.json('$..output')))
$parsedPayload
EOF_RESPONSE
  standard_response = <<EOF_RESPONSE
#set($body = $input.path('$'))
{
  "id": "$body.executionArn",
  "status": "ACCEPTED",
  "message": "Workflow started successfully"
}
EOF_RESPONSE
}

# --------------------------------------------------------
# API Gateway route resources
# --------------------------------------------------------

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_resource_id
  path_part   = var.api_path
}

resource "aws_api_gateway_resource" "status" {
  count       = var.enable_status_check ? 1 : 0
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.resource.id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "execution_id" {
  count       = var.enable_status_check ? 1 : 0
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.status[0].id
  path_part   = "{execution_id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.resource.id
  http_method          = var.http_method
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.request_validator.id
  request_models = {
    "application/json" = aws_api_gateway_model.model.name
  }
}

resource "aws_api_gateway_method" "get_status" {
  count                = var.enable_status_check ? 1 : 0
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.execution_id[0].id
  http_method          = "GET"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.request_validator.id
  request_parameters = {
    "method.request.path.execution_id" = true
  }
}

# --------------------------------------------------------
# API validator
# --------------------------------------------------------

resource "aws_api_gateway_request_validator" "request_validator" {
  rest_api_id                 = var.rest_api_id
  name                        = "${local.camel_case_route_name}RequestValidator"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "model" {
  rest_api_id  = var.rest_api_id
  name         = "${local.camel_case_route_name}Model"
  content_type = "application/json"
  schema       = jsonencode(var.schema)
}

# --------------------------------------------------------
# IAM role for API Gateway
# --------------------------------------------------------

data "aws_iam_policy_document" "gateway_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gateway_role" {
  name               = "${var.route_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.gateway_role_policy.json
}

# -------------------------------------------------------
# Policy to execute step function
# -------------------------------------------------------

data "aws_iam_policy_document" "trigger_step_function_policy" {
  statement {
    actions = [
      "states:StartExecution",
      "states:StartSyncExecution",
      "states:DescribeExecution",
    ]
    effect = "Allow"
    resources = [
      var.step_function.arn,
      "${replace(var.step_function.arn, "stateMachine", local.sfn_arn_type)}:*",
    ]
  }
}

resource "aws_iam_policy" "trigger_step_function_policy" {
  name   = "trigger-${substr(var.route_name, 0, 45)}-policy"
  policy = data.aws_iam_policy_document.trigger_step_function_policy.json
}

resource "aws_iam_role_policy_attachment" "trigger_step_function" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.trigger_step_function_policy.arn
}

# -------------------------------------------------------
# API integration with step function
# -------------------------------------------------------

data "aws_region" "current" {}

resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/Start${local.sync}Execution"

  credentials = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF_REQUEST
{
  "input": "$util.escapeJavaScript($input.json('$'))",
  "stateMachineArn": "${var.step_function.arn}"
}
EOF_REQUEST
  }
}

resource "aws_api_gateway_integration" "status_integration" {
  count                   = var.enable_status_check ? 1 : 0
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.execution_id[0].id
  http_method             = aws_api_gateway_method.get_status[0].http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/DescribeExecution"

  credentials = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF_REQUEST
{
  "executionArn": "${replace(var.step_function.arn, "stateMachine", local.sfn_arn_type)}:$input.params('execution_id')"
}
EOF_REQUEST
  }
}

# -------------------------------------------------------
# API responses
# -------------------------------------------------------

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "status_200" {
  count       = var.enable_status_check ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.execution_id[0].id
  http_method = aws_api_gateway_method.get_status[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "status_404" {
  count       = var.enable_status_check ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.execution_id[0].id
  http_method = aws_api_gateway_method.get_status[0].http_method
  status_code = "404"
}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_templates = {
    "application/json" = var.sfn_type == "express" ? local.express_response : local.standard_response
  }
  depends_on = [
    aws_api_gateway_integration.step_function_integration,
  ]
}

resource "aws_api_gateway_integration_response" "status_integration_response" {
  count       = var.enable_status_check ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.execution_id[0].id
  http_method = aws_api_gateway_method.get_status[0].http_method
  status_code = "200"

  response_templates = {
    "application/json" = <<EOF_RESPONSE
#set($input = $input.path('$'))
#set($type = $input.get("__type"))
#if($type && $type.contains("ExecutionDoesNotExist"))
    #set($context.responseOverride.status = 404)
    {
      "error": "NotFound",
      "cause": "Step Function execution with the provided ID does not exist."
    }
#else
    {
      "execution_id": "$input.name",
      "status": "$input.status",
      #if($input.status == "SUCCEEDED")
        "output": $input.output
      #elseif($input.status == "FAILED")
        "error": "$util.escapeJavaScript($input.error)",
        "cause": "$util.escapeJavaScript($input.cause)"
      #else
        "output": ""
      #end
    }
#end
EOF_RESPONSE
  }
  depends_on = [
    aws_api_gateway_integration.status_integration,
  ]
}

resource "aws_api_gateway_integration_response" "integration_response_500" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "500"

  response_templates = {
    "application/json" = "{\"message\": \"Internal error from Step Function.\"}"
  }
  selection_pattern = ".*\"status\":500.*"
  depends_on = [
    aws_api_gateway_integration.step_function_integration,
  ]
}
