resource "aws_sns_topic" "delius_oasys" {
  for_each = local.delius_oasys_queues

  name = "${each.key}-delius-oasys-topic"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-topic"
  })
}

resource "aws_sqs_queue" "delius_oasys" {
  for_each = local.delius_oasys_queues

  name = "${each.key}-delius-oasys-queue"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-queue"
  })
}

resource "aws_sqs_queue_policy" "delius_oasys" {
  for_each = local.delius_oasys_queues

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
            "aws:SourceArn" = aws_sns_topic.delius_oasys[each.key].arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "delius_oasys" {
  for_each = local.delius_oasys_queues

  topic_arn = aws_sns_topic.delius_oasys[each.key].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.delius_oasys[each.key].arn
}

resource "aws_iam_user" "delius_oasys" {
  for_each = local.delius_oasys_queues

  name = "${each.key}-delius-oasys-queue-user"

  tags = merge(local.tags, {
    Name = "${each.key}-delius-oasys-queue-user"
  })
}

resource "aws_iam_access_key" "delius_oasys" {
  for_each = local.delius_oasys_queues

  user = aws_iam_user.delius_oasys[each.key].name
}

resource "aws_iam_policy" "delius_oasys" {
  for_each = local.delius_oasys_queues

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
}

resource "aws_iam_user_policy_attachment" "delius_oasys" {
  for_each = local.delius_oasys_queues

  user       = aws_iam_user.delius_oasys[each.key].name
  policy_arn = aws_iam_policy.delius_oasys[each.key].arn
}

resource "aws_secretsmanager_secret" "delius_oasys" {
  for_each = local.delius_oasys_queues

  #checkov:skip=CKV2_AWS_57:Ensure Secrets Manager secrets should have automatic rotation enabled

  name                    = "/delius_oasys/${each.key}/queue"
  description             = "Secrets for delis_oasys SQS queue"
  kms_key_id              = module.environment.kms_keys["general"].arn
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Name = "/delius_oasys/${each.key}/queue"
  })
}

resource "aws_secretsmanager_secret_version" "delius_oasys" {
  for_each = local.delius_oasys_queues

  secret_id = aws_secretsmanager_secret.delius_oasys[each.key].id
  secret_string = jsonencode({
    topic_arn     = aws_sns_topic.delius_oasys[each.key].arn
    queue_url     = aws_sqs_queue.delius_oasys[each.key].id
    client_id     = aws_iam_access_key.delius_oasys[each.key].id
    client_secret = aws_iam_access_key.delius_oasys[each.key].secret
  })
}
