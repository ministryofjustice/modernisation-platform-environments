data "aws_iam_policy_document" "apigateway_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "authoriser_role" {
  name               = "authoriser_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "allow_invoke_authoriser_lambda_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_product_authorizer_lambda.lambda_function_arn]
  }
}

resource "aws_iam_policy" "allow_invoke_authoriser_lambda" {
  name   = "allow_invoke_authoriser_lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_invoke_authoriser_lambda_doc.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_allow_invoke_authoriser_lambda" {
  role       = aws_iam_role.authoriser_role.name
  policy_arn = aws_iam_policy.allow_invoke_authoriser_lambda.arn
}

resource "aws_iam_role" "authoriser_lambda_role" {
  name               = "authoriser_lambda_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
  tags               = local.tags
}

module "data_product_authorizer_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.1"
  application_name               = "data_product_authorizer"
  tags                           = local.tags
  description                    = "Lambda to authorize access to endpoints"
  create_role                    = false
  function_name                  = "data_product_authorizer_${local.environment}"
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-auhorizer-lambda-ecr-repo:1.0.0"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = {
    authorizationToken = "placeholder"
    api_resource_arn   = "${aws_api_gateway_rest_api.data_platform.execution_arn}/*/*"
  }

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action        = "lambda:InvokeFunction"
      function_name = "data_product_authorizer_${local.environment}"
      principal     = "apigateway.amazonaws.com"
      source_arn    = "${aws_api_gateway_rest_api.data_platform.execution_arn}/*/*"
    }
  }

}
