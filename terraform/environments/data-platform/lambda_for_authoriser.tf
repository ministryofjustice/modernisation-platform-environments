data "archive_file" "authoriser_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/authoriser"
  output_path = "${path.module}/src/authoriser_${local.environment}/authoriser_lambda.zip"
}

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

resource "aws_iam_role" "authoriser_lambda_role" {
  name               = "authoriser_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "allow_invoke_authoriser_lambda_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.authoriser.arn]
  }
}

resource "aws_iam_policy" "allow_invoke_authoriser_lambda" {
  name   = "allow_invoke_authoriser_lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_invoke_authoriser_lambda_doc.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_allow_invoke_authoriser_lambda" {
  role       = aws_iam_role.authoriser_lambda_role.name
  policy_arn = aws_iam_policy.allow_invoke_authoriser_lambda.arn
}

resource "aws_lambda_function" "authoriser" {
  function_name    = "authoriser_${local.environment}"
  description      = "api gateway authoriser"
  handler          = "main.handler"
  runtime          = local.lambda_runtime
  filename         = data.archive_file.authoriser_zip.output_path
  source_code_hash = data.archive_file.authoriser_zip.output_base64sha256
  role             = aws_iam_role.authoriser_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_code_lambda_policy_to_iam_role]
  environment {
    variables = {
      Authorization    = "placeholder"
      api_resource_arn = "${aws_api_gateway_rest_api.data_platform.arn}/*/*"
    }
  }
  tags = local.tags
}
