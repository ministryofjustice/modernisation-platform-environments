data "archive_file" "authoriser_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/authoriser"
  output_path = "${path.module}/src/authoriser_${local.environment}/authoriser_lambda.zip"
}

resource "aws_iam_role" "authoriser_lambda_role" {
  name               = "authoriser_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
  tags               = local.tags
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
