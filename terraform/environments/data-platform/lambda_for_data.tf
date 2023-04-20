data "archive_file" "data_extractor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/data_extractor_${local.environment}"
  output_path = "${path.module}/src/data_extractor_${local.environment}/data_extractor_lambda.zip"
}

resource "aws_lambda_function" "data_extractor" {
  function_name    = "data_extractor_${local.environment}"
  description      = "Lambda to extract code and store in another location"
  handler          = "main.handler"
  runtime          = local.lambda_runtime
  timeout          = local.lambda_timeout_in_seconds
  filename         = data.archive_file.data_extractor_zip.output_path
  source_code_hash = data.archive_file.data_extractor_zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.data_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_data_lambda_policy_to_iam_role]
  environment {
    variables = {
      ENVIRONMENT   = local.environment
      GLUE_JOB_NAME = aws_glue_job.glue_job.name
    }
  }
}

data "aws_iam_policy_document" "data_lambda_trust_policy_doc" {
  statement {
    sid     = "LambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "data_lambda_role" {
  name               = "data_extractor_${local.environment}-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.data_lambda_trust_policy_doc.json
}

data "aws_iam_policy_document" "iam_policy_document_for_data_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid       = "StartGlueJobRun"
    effect    = "Allow"
    actions   = ["glue:StartJobRun"]
    resources = [aws_glue_job.glue_job.arn]
  }
}

resource "aws_iam_policy" "data_lambda_policy" {
  name        = "data_extractor_${local.environment}-policy-${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_data_lambda.json

}

resource "aws_iam_role_policy_attachment" "attach_data_lambda_policy_to_iam_role" {
  role       = aws_iam_role.code_lambda_role.name
  policy_arn = aws_iam_policy.data_lambda_policy.arn
}

resource "aws_cloudwatch_event_rule" "put_to_data_directory" {
  name = "put_to_data_directory"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject"],
      "requestParameters" : {
        "bucketName" : [module.s3-bucket.bucket.id],
        "key" : [{ "prefix" : "raw_data/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "data_directory_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_data_directory.name
  target_id = "data"
  arn       = aws_lambda_function.data_extractor.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_data_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_extractor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_data_directory.arn
}

