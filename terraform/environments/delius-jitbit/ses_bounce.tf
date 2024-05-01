resource "aws_sns_topic" "jitbit_ses_destination_topic_bounce_email_notification" {
  name = format("%s-ses-destination-topic-bounce-email-notification", local.application_name)

  tags = local.tags
}

resource "aws_sesv2_configuration_set_event_destination" "jitbit_ses_event_destination_bounce_email_notification" {
  configuration_set_name = aws_sesv2_configuration_set.jitbit_ses_configuration_set.configuration_set_name
  event_destination_name = format("%s-event-destination-bounce-email-notification", local.application_name)

  event_destination {
    sns_destination {
      topic_arn = aws_sns_topic.jitbit_ses_destination_topic_bounce_email_notification.arn
    }
    enabled = true
    matching_event_types = [
      "BOUNCE"
    ]
  }
}

data "archive_file" "lambda_function_payload_bounce_email_notification" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/bounce_email_notification/"
  output_path = "${path.module}/lambda/bounce_email_notification/bounce_email_notification.zip"
  excludes    = ["bounce_email_notification.zip"]
}

resource "aws_lambda_function" "bounce_email_notification" {
  filename         = "${path.module}/lambda/bounce_email_notification/bounce_email_notification.zip"
  function_name    = "bounce_email_notification"
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda_bounce_email_notification.arn
  runtime          = "python3.12"
  handler          = "bounce_email_notification.handler"
  source_code_hash = data.archive_file.lambda_function_payload_bounce_email_notification.output_base64sha256

  tags = local.tags
}

resource "aws_iam_role" "lambda_bounce_email_notification" {
  name               = "bounce_email_notification-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_bounce_email_notification.json

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy_bounce_email_notification" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_bounce_email_notification" {
  name   = "lambda"
  role   = aws_iam_role.lambda_bounce_email_notification.id
  policy = data.aws_iam_policy_document.lambda_assume_role_policy_bounce_email_notification.json
}

data "aws_iam_policy_document" "lambda_policy_bounce_email_notification" {
  statement {
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail"
    ]
    resources = ["*"]
  }
}

resource "aws_lambda_permission" "sns_bounce_email_notification" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bounce_email_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.jitbit_ses_destination_topic_bounce_email_notification.arn
}

resource "aws_sns_topic_subscription" "lambda_bounce_email_notification" {
  topic_arn = aws_sns_topic.jitbit_ses_destination_topic_bounce_email_notification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bounce_email_notification.arn
}
