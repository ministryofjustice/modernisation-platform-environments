resource "aws_sqs_queue_policy" "patch_ccms_policy" {
  count     = local.environment == "test" ? 1 : 0
  queue_url = aws_sqs_queue.patch_ccms_provider_q[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.patch_ccms_provider_q[0].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.patch_provider_banks[0].arn
        }
      }
    }]
  })
}
###############################################
### DLQ Policies
###############################################
resource "aws_sqs_queue_policy" "patch_ccms_dlq_policy" {
  count     = local.environment == "test" ? 1 : 0
  queue_url = aws_sqs_queue.patch_ccms_provider_dlq[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.patch_ccms_provider_dlq[0].arn
    }]
  })
}