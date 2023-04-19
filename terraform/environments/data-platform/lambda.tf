data "archive_file" "code_extractor_zip" {
  type        = "zip"
  source_dir  = local.code_function_source_dir
  output_path = "${local.code_function_source_dir}/code_extractor_lambda.zip"
}

data "archive_file" "data_extractor_zip" {
  type        = "zip"
  source_dir  = local.data_function_source_dir
  output_path = "${local.data_function_source_dir}/data_extractor_lambda.zip"
}


resource "aws_lambda_function" "code_extractor" {
  function_name    = "${local.code_function_name}-${local.environment}"
  description      = "Lambda to extract code and store in another location"
  handler          = local.code_function_handler
  runtime          = local.code_function_runtime
  timeout          = local.code_function_timeout_in_seconds
  filename         = data.archive_file.code_extractor_zip.output_path
  source_code_hash = data.archive_file.code_extractor_zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.code_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_code_lambda_policy_to_iam_role]
  environment {
    variables = {
      ENVIRONMENT = local.environment
      GLUE_JOB_NAME = "placeholder"
    }
  }
}

resource "aws_lambda_function" "data_extractor" {
  function_name    = "${local.data_function_name}-${local.environment}"
  description      = "Lambda to extract code and store in another location"
  handler          = local.data_function_handler
  runtime          = local.data_function_runtime
  timeout          = local.data_function_timeout_in_seconds
  filename         = data.archive_file.data_extractor_zip.output_path
  source_code_hash = data.archive_file.data_extractor_zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.data_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_data_lambda_policy_to_iam_role]
  environment {
    variables = {
      ENVIRONMENT = local.environment
    }
  }
}

data "aws_iam_policy_document" "lambda_trust_policy_doc" {
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

resource "aws_iam_role" "code_lambda_role" {
  name               = "${local.code_function_name}-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
}

resource "aws_iam_role" "data_lambda_role" {
  name               = "${local.data_function_name}-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
}

data "aws_iam_policy_document" "iam_policy_document_for_code_lambda" {
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
    resources = ["${module.s3-bucket.bucket.arn}/code_zips/*"]
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_data_lambda" {
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
    resources = ["${module.s3-bucket.bucket.arn}/raw_data/*"]
  }
}

resource "aws_iam_policy" "code_lambda_policy" {
  name        = "${local.code_function_name}-policy-${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_code_lambda.json

}

resource "aws_iam_policy" "data_lambda_policy" {
  name        = "${local.data_function_name}-policy-${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_data_lambda.json

}

resource "aws_iam_role_policy_attachment" "attach_code_lambda_policy_to_iam_role" {
  role       = aws_iam_role.code_lambda_role.name
  policy_arn = aws_iam_policy.code_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_data_lambda_policy_to_iam_role" {
  role       = aws_iam_role.code_lambda_role.name
  policy_arn = aws_iam_policy.data_lambda_policy.arn
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

resource "aws_cloudwatch_event_target" "code_directory_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_code_directory.name
  target_id = "code"
  arn       = aws_lambda_function.code_extractor.arn
}

resource "aws_cloudwatch_event_target" "data_directory_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.put_to_data_directory.name
  target_id = "data"
  arn       = aws_lambda_function.data_extractor.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_code_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.code_extractor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_code_directory.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_data_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_extractor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_to_data_directory.arn
}

