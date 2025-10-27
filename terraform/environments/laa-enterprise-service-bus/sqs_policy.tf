resource "aws_sqs_queue_policy" "maat_policy" {
  queue_url = aws_sqs_queue.maat_provider_q.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.maat_provider_q.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.priority_p1.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "cclf_policy" {
  queue_url = aws_sqs_queue.cclf_provider_q.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.cclf_provider_q.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.priority_p1.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "ccr_policy" {
  queue_url = aws_sqs_queue.ccr_provider_q.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.ccr_provider_q.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.priority_p1.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "ccms_policy" {
  queue_url = aws_sqs_queue.ccms_provider_q.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.ccms_provider_q.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.provider_banks.arn
        }
      }
    }]
  })
}
###############################################
### DLQ Policies
###############################################
resource "aws_sqs_queue_policy" "maat_dlq_policy" {
  queue_url = aws_sqs_queue.maat_provider_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.maat_provider_dlq.arn
    }]
  })
}

resource "aws_sqs_queue_policy" "cclf_dlq_policy" {
  queue_url = aws_sqs_queue.cclf_provider_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.cclf_provider_dlq.arn
    }]
  })
}

resource "aws_sqs_queue_policy" "ccr_dlq_policy" {
  queue_url = aws_sqs_queue.ccr_provider_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.ccr_provider_dlq.arn
    }]
  })
}

resource "aws_sqs_queue_policy" "ccms_dlq_policy" {
  queue_url = aws_sqs_queue.ccms_provider_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.ccms_provider_dlq.arn
    }]
  })
}