data "archive_file" "code_extractor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/code_extractor_${local.environment}"
  output_path = "${path.module}/src/code_extractor_${local.environment}/code_extractor_lambda.zip"
}

resource "aws_lambda_function" "code_extractor" {
  function_name    = "code_extractor_${local.environment}"
  description      = "Lambda to extract code and store in another location"
  handler          = "main.handler"
  runtime          = local.lambda_runtime
  timeout          = local.lambda_timeout_in_seconds
  filename         = data.archive_file.code_extractor_zip.output_path
  source_code_hash = data.archive_file.code_extractor_zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.code_extractor_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_code_lambda_policy_to_iam_role]
  environment {
    variables = {
      ENVIRONMENT = local.environment
    }
  }
}

resource "aws_iam_role" "code_extractor_lambda_role" {
  name               = "code_extractor_${local.environment}-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
}

data "aws_iam_policy_document" "iam_policy_document_for_code_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
  statement {
    sid       = "GetZipFile"
    effect    = "Allow"
    actions   = ["s3:GetObject*"]
    resources = ["${module.s3-bucket.bucket.arn}/code_zips/*"]
  }
  statement {
    sid       = "PutExtractedFiles"
    effect    = "Allow"
    actions   = ["s3:PutObject*"]
    resources = ["${module.s3-bucket.bucket.arn}/code/*"]
  }
}

resource "aws_iam_policy" "code_extractor_lambda_policy" {
  name        = "code_extractor_${local.environment}-policy-${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing code_extractor lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_code_lambda.json

}

resource "aws_iam_role_policy_attachment" "attach_code_lambda_policy_to_iam_role" {
  role       = aws_iam_role.code_extractor_lambda_role.name
  policy_arn = aws_iam_policy.code_extractor_lambda_policy.arn
}

resource "aws_cloudwatch_event_rule" "put_to_code_directory" {
  name = "put_to_code_directory"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject"],
      "requestParameters" : {
        "bucketName" : [module.s3-bucket.bucket.id],
        "key" : [{ "prefix" : "code_zips/" }]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "code_directory_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_code_directory.name
  target_id = "code"
  arn       = aws_lambda_function.code_extractor.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_code_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.code_extractor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_code_directory.arn
}
