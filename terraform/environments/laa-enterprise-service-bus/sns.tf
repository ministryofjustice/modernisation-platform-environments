######################################
### SNS Topic for Priority P1 Messages
######################################

resource "aws_sns_topic" "priority_p1" {
  name = "Priority-P1"
}


######################################
### Subscribe SQS queues to SNS Topic
######################################
resource "aws_sns_topic_subscription" "ccms" {
  topic_arn = aws_sns_topic.priority_p1.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ccms_provider_q.arn
}

resource "aws_sns_topic_subscription" "maat" {
  topic_arn = aws_sns_topic.priority_p1.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.maat_provider_q.arn
}

resource "aws_sns_topic_subscription" "cclf" {
  topic_arn = aws_sns_topic.priority_p1.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.cclf_provider_q.arn
}

resource "aws_sns_topic_subscription" "ccr" {
  topic_arn = aws_sns_topic.priority_p1.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ccr_provider_q.arn
}