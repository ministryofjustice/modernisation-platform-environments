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
      "BOUNCE",
      "DELIVERY_DELAY"
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

  timeout = 6

  environment {
    variables = {
      RATE_LIMIT     = 5
      DYNAMODB_TABLE = aws_dynamodb_table.bounce_email_notification.name
      FROM_ADDRESS   = "notifications@${aws_sesv2_email_identity.jitbit.email_identity}"
    }
  }

  lifecycle {
    replace_triggered_by = [aws_iam_role.lambda_bounce_email_notification]
  }

  tags = local.tags
}

resource "aws_iam_role" "lambda_bounce_email_notification" {
  name               = "bounce_email_notification-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda_bounce_email_notification" {
  name   = "lambda_bounce_email_notification"
  role   = aws_iam_role.lambda_bounce_email_notification.id
  policy = data.aws_iam_policy_document.lambda_policy_bounce_email_notification.json
}

data "aws_iam_policy_document" "lambda_policy_bounce_email_notification" {
  statement {
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.bounce_email_notification.arn]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [data.aws_kms_key.general_shared.arn]
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

resource "aws_cloudwatch_log_group" "bounce_email_notification" {
  name              = "/aws/lambda/bounce_email_notification"
  retention_in_days = 3

  tags = local.tags
}


resource "aws_dynamodb_table" "bounce_email_notification" {
  name         = "bounce_email_notification"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email_ticket_id"

  server_side_encryption {
    enabled     = true
    kms_key_arn = data.aws_kms_key.general_shared.arn
  }

  ttl {
    attribute_name = "expireAt"
    enabled        = true
  }

  attribute {
    name = "email_ticket_id"
    type = "S"
  }

  tags = local.tags
}

resource "aws_dynamodb_resource_policy" "bounce_email_notification" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.lambda_bounce_email_notification.arn
        },
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Resource = aws_dynamodb_table.bounce_email_notification.arn
      }
    ]
  })
  resource_arn = aws_dynamodb_table.bounce_email_notification.arn
}
