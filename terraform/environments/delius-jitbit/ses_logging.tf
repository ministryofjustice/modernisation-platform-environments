#####################
# SES Logging
#####################
resource "aws_sns_topic" "jitbit_ses_destination_topic" {
  name = format("%s-ses-destination-topic", local.application_name)

  tags = local.tags
}

resource "aws_sesv2_configuration_set_event_destination" "jitbit_ses_event_destination" {
  configuration_set_name = aws_sesv2_configuration_set.jitbit_ses_configuration_set.configuration_set_name
  event_destination_name = format("%s-event-destination", local.application_name)

  event_destination {
    sns_destination {
      topic_arn = aws_sns_topic.jitbit_ses_destination_topic.arn
    }
    enabled = true
    matching_event_types = [
      "BOUNCE",
      "COMPLAINT",
      "DELIVERY",
      "DELIVERY_DELAY",
      "REJECT",
      "SEND"
    ]
  }
}

data "archive_file" "lambda_function_payload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/sns_to_cloudwatch"
  output_path = "${path.module}/lambda/sns_to_cloudwatch/sns_to_cloudwatch.zip"
  excludes    = ["sns_to_cloudwatch.zip"]
}

resource "aws_lambda_function" "sns_to_cloudwatch" {
  filename         = "${path.module}/lambda/sns_to_cloudwatch/sns_to_cloudwatch.zip"
  function_name    = "sns_to_cloudwatch"
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda_logging.arn
  runtime          = "python3.12"
  handler          = "sns_to_cloudwatch.handler"
  source_code_hash = data.archive_file.lambda_function_payload.output_base64sha256

  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.sns_logs.name
    }
  }

  lifecycle {
    replace_triggered_by = [aws_iam_role.lambda_logging]
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "sns_logs" {
  name              = format("%s-ses-logs", local.application_name)
  retention_in_days = local.application_data.accounts[local.environment].ses_log_retention_days

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "execution_logs" {
  name              = format("/aws/lambda/%s", aws_lambda_function.sns_to_cloudwatch.function_name)
  retention_in_days = 3

  tags = local.tags
}

resource "aws_iam_role" "lambda_logging" {
  name               = "sns_to_cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  name   = "lambda-logging"
  role   = aws_iam_role.lambda_logging.id
  policy = data.aws_iam_policy_document.lambda_logging__policy.json
}

data "aws_iam_policy_document" "lambda_logging__policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_to_cloudwatch.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.jitbit_ses_destination_topic.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.jitbit_ses_destination_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_to_cloudwatch.arn
}
