locals {
  # don't create infra until the SNS topic ARN has been populated
  delius_oasys_queues_with_topic_arns = {
    for key, value in local.delius_oasys_queues :
    key => value if lookup(value, "sns_topic_arn_configured", true)
  }
}

resource "aws_secretsmanager_secret" "delius_oasys_config" {
  for_each = local.is-development ? {} : local.delius_oasys_queues

  #checkov:skip=CKV2_AWS_57:Ensure Secrets Manager secrets should have automatic rotation enabled

  name                    = "/delius_oasys/${each.key}/config"
  description             = "Configuration for delius_oasys queue integration"
  kms_key_id              = module.environment.kms_keys["general"].arn
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Name = "/delius_oasys/${each.key}/config"
  })
}

data "aws_secretsmanager_secret_version" "delius_oasys_config" {
  for_each = local.is-development ? {} : local.delius_oasys_queues_with_topic_arns

  secret_id = aws_secretsmanager_secret.delius_oasys_config[each.key].id
}

resource "aws_sns_topic" "delius_oasys" {
  for_each = local.is-development ? local.delius_oasys_queues : {}

  name = "${each.key}-delius-oasys-topic"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-topic"
  })
}

locals {
  # in development we create our own SNS topic for testing
  # in other environments we retrieve the SNS topic from the /delius_oasys/{env}/config secret
  delius_oasys_sns_topic_arns = {
    for key, value in local.delius_oasys_queues_with_topic_arns :
    key => local.is-development ? aws_sns_topic.delius_oasys[key].arn : jsondecode(data.aws_secretsmanager_secret_version.delius_oasys_config[key].secret_string)["sns_topic_arn"]
  }
}

resource "aws_sqs_queue" "delius_oasys" {
  for_each = local.delius_oasys_queues

  name = "${each.key}-delius-oasys-queue"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-queue"
  })
}

resource "aws_sqs_queue_policy" "delius_oasys" {
  for_each = local.delius_oasys_queues_with_topic_arns

  queue_url = aws_sqs_queue.delius_oasys[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.delius_oasys[each.key].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = local.delius_oasys_sns_topic_arns[each.key]
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "delius_oasys" {
  for_each = local.delius_oasys_queues_with_topic_arns

  endpoint = aws_sqs_queue.delius_oasys[each.key].arn
  filter_policy = local.is-development ? null : jsonencode({
    eventType = ["probation-case.sentence.terminated"]
  })
  protocol  = "sqs"
  topic_arn = local.delius_oasys_sns_topic_arns[each.key]
}

resource "aws_iam_user" "delius_oasys" {
  for_each = local.is-development ? local.delius_oasys_queues : {}

  name = "${each.key}-delius-oasys-queue-user"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-queue-user"
  })
}

resource "aws_iam_access_key" "delius_oasys" {
  for_each = local.is-development ? local.delius_oasys_queues : {}

  user = aws_iam_user.delius_oasys[each.key].name
}

resource "aws_iam_policy" "delius_oasys" {
  for_each = local.is-development ? local.delius_oasys_queues : {}

  name = "${each.key}-delius-oasys-sqs-poll-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.delius_oasys[each.key].arn
        Condition = {
          IpAddress = {
            "aws:SourceIp" = each.value.ip_allow_list
          }
        }
      },
    ]
  })

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-sqs-poll-policy"
  })
}

resource "aws_iam_user_policy_attachment" "delius_oasys" {
  for_each = local.is-development ? local.delius_oasys_queues : {}

  user       = aws_iam_user.delius_oasys[each.key].name
  policy_arn = aws_iam_policy.delius_oasys[each.key].arn
}

resource "aws_secretsmanager_secret" "delius_oasys" {
  for_each = local.delius_oasys_queues

  #checkov:skip=CKV2_AWS_57:Ensure Secrets Manager secrets should have automatic rotation enabled

  name                    = "/delius_oasys/${each.key}/queue"
  description             = "Secrets for delius_oasys SQS queue"
  kms_key_id              = module.environment.kms_keys["general"].arn
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Name = "/delius_oasys/${each.key}/queue"
  })
}

resource "aws_secretsmanager_secret_version" "delius_oasys" {
  for_each = local.delius_oasys_queues_with_topic_arns

  secret_id = aws_secretsmanager_secret.delius_oasys[each.key].id
  secret_string = local.is-development ? jsonencode({
    topic_arn     = local.delius_oasys_sns_topic_arns[each.key]
    queue_url     = aws_sqs_queue.delius_oasys[each.key].id
    client_id     = aws_iam_access_key.delius_oasys[each.key].id
    client_secret = aws_iam_access_key.delius_oasys[each.key].secret
    }) : jsonencode({
    topic_arn = local.delius_oasys_sns_topic_arns[each.key]
    queue_url = aws_sqs_queue.delius_oasys[each.key].id
  })
}
