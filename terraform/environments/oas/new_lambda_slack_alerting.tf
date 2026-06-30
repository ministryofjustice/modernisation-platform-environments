######################################
### SNS Topic for Security Alarms
######################################

resource "aws_sns_topic" "oas_security_alerts" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-security-alerts-${local.environment}"

  tags = merge(
    local.tags,
    { Name = "oas-security-alerts-${local.environment}" }
  )
}

######################################
### Lambda Security Group
######################################

resource "aws_security_group" "security_alerts_lambda_sg" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name        = "oas-${local.environment}-security-alerts-lambda-sg"
  description = "Security Alerts Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-security-alerts-lambda-sg" }
  )
}

resource "aws_security_group_rule" "security_alerts_lambda_https_to_internet" {
  count             = contains(["preproduction", "development"], local.environment) ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_alerts_lambda_sg[0].id
  description       = "Allow outbound HTTPS to any destination (0.0.0.0/0) for Slack webhook"
}

######################################
### Lambda Function
######################################

# Create ZIP file from Python source
data "archive_file" "security_alerts_lambda_zip" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/security_alerts_slack/lambda_function.py"
  output_path = "${path.module}/lambda/security_alerts_slack/lambda_function.zip"
}

resource "aws_lambda_function" "security_alerts_to_slack" {
  count            = contains(["preproduction", "development"], local.environment) ? 1 : 0
  description      = "Lambda function to send CloudWatch security alarms to Slack."
  function_name    = "oas-security-alerts-to-slack-${local.environment}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  role             = aws_iam_role.security_alerts_lambda_role[0].arn
  filename         = data.archive_file.security_alerts_lambda_zip[0].output_path
  source_code_hash = data.archive_file.security_alerts_lambda_zip[0].output_base64sha256
  timeout          = 60

  environment {
    variables = {
      SLACK_WEBHOOK_SECRET_NAME = aws_secretsmanager_secret.slack_security_alerts_webhook[0].name
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.security_alerts_lambda_sg[0].id]
    subnet_ids         = data.aws_subnets.shared-private.ids
  }

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-security-alerts-to-slack" }
  )
}

######################################
### Lambda Permissions for SNS
######################################

resource "aws_lambda_permission" "allow_sns_invoke" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_alerts_to_slack[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.oas_security_alerts[0].arn
}

######################################
### SNS Subscription to Lambda
######################################

resource "aws_sns_topic_subscription" "security_alerts_lambda_subscription" {
  count     = contains(["preproduction", "development"], local.environment) ? 1 : 0
  topic_arn = aws_sns_topic.oas_security_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.security_alerts_to_slack[0].arn
}

######################################
### IAM Resources
######################################

resource "aws_iam_role" "security_alerts_lambda_role" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-security-alerts-lambda-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-security-alerts-lambda-role" }
  )
}

resource "aws_iam_policy" "security_alerts_lambda_policy" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-security-alerts-lambda-policy-${local.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.slack_security_alerts_webhook[0].arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.security_alerts_to_slack[0].function_name}:*"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-security-alerts-lambda-policy" }
  )
}

resource "aws_iam_role_policy_attachment" "security_alerts_lambda_policy_attach" {
  count      = contains(["preproduction", "development"], local.environment) ? 1 : 0
  role       = aws_iam_role.security_alerts_lambda_role[0].name
  policy_arn = aws_iam_policy.security_alerts_lambda_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "security_alerts_lambda_vpc_access" {
  count      = contains(["preproduction", "development"], local.environment) ? 1 : 0
  role       = aws_iam_role.security_alerts_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

######################################
### Auto-configure CloudWatch Alarms
######################################

# List of security alarms that need SNS action configured
locals {
  security_alarm_names = [
    "cloudtrail-configuration-changes",
    "cmk-removal",
    "config-configuration-changes",
    "iam-policy-changes",
    "s3-bucket-policy-changes",
    "security-group-changes",
    "unauthorised-api-calls"
  ]
}

# Automatically add SNS topic to CloudWatch alarms
resource "null_resource" "update_security_alarms" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0

  # Trigger update when SNS topic changes or alarm list changes
  triggers = {
    sns_topic_arn = aws_sns_topic.oas_security_alerts[0].arn
    alarm_names   = join(",", local.security_alarm_names)
  }

  # Add SNS topic to each alarm
  provisioner "local-exec" {
    command = <<-EOT
      for alarm in ${join(" ", local.security_alarm_names)}; do
        echo "Updating CloudWatch alarm: $alarm"

        # Get existing alarm configuration
        alarm_config=$(aws cloudwatch describe-alarms \
          --alarm-names "$alarm" \
          --region ${data.aws_region.current.name} \
          --output json)

        # Extract existing alarm actions (to preserve them)
        existing_actions=$(echo "$alarm_config" | jq -r '.MetricAlarms[0].AlarmActions[]' 2>/dev/null | tr '\n' ' ')

        # Check if SNS topic already exists in actions
        if echo "$existing_actions" | grep -q "${aws_sns_topic.oas_security_alerts[0].arn}"; then
          echo "  ✓ SNS topic already configured for $alarm"
        else
          echo "  → Adding SNS topic to $alarm"

          # Add SNS topic to alarm actions (preserving existing actions)
          all_actions="${aws_sns_topic.oas_security_alerts[0].arn} $existing_actions"

          aws cloudwatch put-metric-alarm \
            --alarm-name "$alarm" \
            --alarm-actions $all_actions \
            --region ${data.aws_region.current.name} || echo "  ⚠ Warning: Could not update $alarm (may not exist in this environment)"
        fi
      done

      echo ""
      echo "✓ CloudWatch alarm configuration complete"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_sns_topic.oas_security_alerts,
    aws_lambda_function.security_alerts_to_slack,
    aws_sns_topic_subscription.security_alerts_lambda_subscription
  ]
}
