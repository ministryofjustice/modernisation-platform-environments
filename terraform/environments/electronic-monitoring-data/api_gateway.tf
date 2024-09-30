# --------------------------------------------------------
# Main API resources
# --------------------------------------------------------

resource "aws_api_gateway_rest_api" "get_zipped_file" {
  name        = "get_zipped_file"
  description = "API Gateway to trigger Step Function to get a unzipped file from zipped store"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "get_zipped_step_function_invoke" {
  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id
  parent_id   = aws_api_gateway_rest_api.get_zipped_file.root_resource_id
  path_part   = "execute"
}

resource "aws_api_gateway_method" "get_zipped_step_function_invoke" {
  rest_api_id      = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id      = aws_api_gateway_resource.get_zipped_step_function_invoke.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# --------------------------------------------------------
# IAM policies
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


resource "aws_iam_role" "get_zipped_gateway_role" {
  name               = "get_zipped_gateway_role"
  assume_role_policy = data.aws_iam_policy_document.gateway_role_policy.json
}

data "aws_iam_policy_document" "trigger_step_function_policy" {
  statement {
    actions   = ["states:StartExecution"]
    effect    = "Allow"
    resources = [module.get_zipped_file.arn]
  }
}

resource "aws_iam_policy" "trigger_step_function_policy" {
  name        = "trigger_step_function_policy"
  description = "Policy to trigger Step Function"
  policy      = data.aws_iam_policy_document.trigger_step_function_policy.json
}

resource "aws_iam_role_policy_attachment" "get_zipped_gateway_trigger_step_function_policy_attachment" {
  role       = aws_iam_role.get_zipped_gateway_role.name
  policy_arn = aws_iam_policy.trigger_step_function_policy.arn
}

resource "aws_api_gateway_integration" "get_zipped_step_function_invoke" {
  rest_api_id             = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id             = aws_api_gateway_resource.get_zipped_step_function_invoke.id
  http_method             = aws_api_gateway_method.get_zipped_step_function_invoke.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:eu-west-2:states:action/StartExecution"

  credentials = aws_iam_role.get_zipped_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.json('$'))",
  "stateMachineArn": "${module.get_zipped_file.arn}"
}
EOF
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      # put some stuff once written
      aws_api_gateway_resource.get_zipped_step_function_invoke,
      aws_api_gateway_method.get_zipped_step_function_invoke,
      aws_api_gateway_integration.get_zipped_step_function_invoke,
      aws_api_gateway_integration_response.integration_response_200,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id = aws_api_gateway_resource.get_zipped_step_function_invoke.id
  http_method = aws_api_gateway_method.get_zipped_step_function_invoke.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id = aws_api_gateway_resource.get_zipped_step_function_invoke.id
  http_method = aws_api_gateway_method.get_zipped_step_function_invoke.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}