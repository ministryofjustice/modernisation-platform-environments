output "sqs_queue" {
  value = aws_sqs_queue.s3_event_queue
}

output "sqs_dlq" {
  value = aws_sqs_queue.s3_event_dlq
}
