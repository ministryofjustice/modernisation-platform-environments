# --------------------------------------------------------
# Main API resources
# --------------------------------------------------------

resource "aws_api_gateway_rest_api" "get_zipped_file" {
  name        = "get_zipped_file"
  description = "API Gateway to trigger Step Function to get a unzipped file from zipped store"
}

resource "aws_api_gateway_resource" "get_zipped_file_resource" {
  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id
  parent_id   = aws_api_gateway_rest_api.get_zipped_file.root_resource_id
  path_part   = "execute"
}

resource "aws_api_gateway_method" "trigger_method" {
  rest_api_id   = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id   = aws_api_gateway_resource.get_zipped_file_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# --------------------------------------------------------
# IAM policies
# --------------------------------------------------------

data "aws_iam_policy_document" "gateway_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = "apigateway.amazonaws.com"
        }
    }
}


resource "aws_iam_role" "get_zipped_gateway_role" {
  name = "get_zipped_gateway_role"
  assume_role_policy = data.aws_iam_policy_document.get_zipped_gateway_role_policy.json
}

data "aws_iam_policy_document" "trigger_step_function_policy" {
    statement {
        actions = ["states:StartExecution"]
        effect = "Allow"
        resources = [module.get_zipped_file.arn]
    }

}

resource "aws_iam_policy" "trigger_step_function_policy" {
  name        = "trigger_step_function_policy"
  description = "Policy to trigger Step Function"
  policy = data.aws_iam_policy_document.trigger_step_function_policy.json
}

resource "aws_iam_role_policy_attachment" "get_zipped_gateway_trigger_step_function_policy_attachment" {
  role       = aws_iam_role.get_zipped_gateway_role.name
  policy_arn = aws_iam_policy.trigger_step_function_policy.arn
}

resource "aws_api_gateway_integration" "get_zipped_gateway_integration" {
  rest_api_id             = aws_api_gateway_rest_api.get_zipped_file.id
  resource_id             = aws_api_gateway_resource.get_zipped_file_resource.id
  http_method             = aws_api_gateway_method.trigger_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-west-2:states:action/StartExecution"

  credentials = aws_iam_role.get_zipped_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "{ \\"file_name\\": \\"$input.json('$.file_name')\\", \\"zip_file_name\\": \\"$input.json('$.zip_file_name')\\" }",
  "stateMachineArn": "${module.get_zipped_file.arn}"
}
EOF
  }
}

resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on = [aws_api_gateway_integration.get_zipped_gateway_integration]

  rest_api_id = aws_api_gateway_rest_api.get_zipped_file.id
  stage_name  = "prod"
}