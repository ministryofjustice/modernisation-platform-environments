module "kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["auth0/${var.name}"]
  description           = "Auth0 KMS Key for ${var.name}"
  enable_default_policy = true

  deletion_window_in_days = 7

  key_statements = [
    {
      sid = "AWSEventBridge"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    },
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.cloudwatch_log_group_name}",
          ]
        }
      ]
    }
  ]

  tags = var.tags
}

resource "aws_cloudwatch_event_bus" "this" {
  name              = data.aws_cloudwatch_event_source.this.name
  event_source_name = data.aws_cloudwatch_event_source.this.name
}

resource "aws_cloudwatch_log_group" "this" {
  name = local.cloudwatch_log_group_name

  kms_key_id        = module.kms_key.key_arn
  retention_in_days = var.retention_in_days
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch"
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
    }
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_name     = var.name
  policy_document = data.aws_iam_policy_document.this.json
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = var.name
  event_bus_name = aws_cloudwatch_event_bus.this.name

  event_pattern = jsonencode({
    source = [{
      prefix = "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "this" {
  target_id      = "auth0-to-cloudwatch-logs"
  event_bus_name = var.event_source_name
  rule           = aws_cloudwatch_event_rule.this.name
  arn            = aws_cloudwatch_log_group.this.arn
}
