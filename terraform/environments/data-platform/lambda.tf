variable "env_name" {
  description = "Environment name"
  default     = "dev"
}


data "archive_file" "zip" {
  type        = "zip"
  source_dir  = local.function_source_dir
  output_path = "${local.function_source_dir}/main-code.zip"
}


resource "aws_lambda_function" "function" {
  function_name    = "${local.function_name}-${var.env_name}"
  description      = "Lambda to extract code and store in another location"
  handler          = local.function_handler
  runtime          = local.function_runtime
  timeout          = local.function_timeout_in_seconds
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  environment {
    variables = {
      ENVIRONMENT = var.env_name
    }
  }
}


resource "aws_iam_role" "lambda_role" {
  name               = "${local.function_name}-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.iam_role_policy_for_lambda.json
}

data "aws_iam_policy_document" "iam_role_policy_for_lambda" {
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

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "${local.function_name}-policy-${var.env_name}"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_lambda.json

}

data "aws_iam_policy_document" "iam_policy_document_for_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid       = "GETPUTBucketAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject*", "s3:PutObject*"]
    resources = ["${module.s3-bucket.bucket.arn}/code/*"]
  }
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
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
        "key" : [{ "prefix" : "code/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "code_directory_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_code_directory.name
  target_id = "code"
  arn       = aws_lambda_function.function.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_code_directory.arn
}
