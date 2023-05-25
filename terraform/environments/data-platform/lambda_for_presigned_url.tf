data "archive_file" "presigned_url_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/presigned_url"
  output_path = "${path.module}/src/presigned_url_${local.environment}/presigned_url_lambda.zip"
}

resource "aws_iam_role" "presigned_url_lambda_role" {
  name               = "presigned_url_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
  tags               = local.tags
}

data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  statement {
    sid       = "GetPutDataObject"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/curated_data/*"]
  }
}

resource "aws_iam_policy" "presigned_url_lambda_policy" {
  name        = "presigned_url_policy_${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing presigned_url lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_presigned_url_lambda_policy_to_iam_role" {
  role       = aws_iam_role.presigned_url_lambda_role.name
  policy_arn = aws_iam_policy.presigned_url_lambda_policy.arn
}

resource "aws_lambda_function" "presigned_url" {
  function_name    = "presigned_url_${local.environment}"
  description      = "api gateway presigned_url"
  handler          = "main.handler"
  runtime          = local.lambda_runtime
  filename         = data.archive_file.presigned_url_zip.output_path
  source_code_hash = data.archive_file.presigned_url_zip.output_base64sha256
  role             = aws_iam_role.presigned_url_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_code_lambda_policy_to_iam_role]
  environment {
    variables = {
      BUCKET_NAME = module.s3-bucket.bucket.id
    }
  }
  tags = local.tags
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.data_platform.execution_arn}/*/${aws_api_gateway_method.upload_data_get.http_method}${aws_api_gateway_resource.upload_data.path}"
}
