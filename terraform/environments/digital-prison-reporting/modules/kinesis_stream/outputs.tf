output "kinesis_stream_name" {
  description = "The unique Kinesis stream name"
  value       = aws_kinesis_stream.this[0].name
}

#output "kinesis_stream_shard_count" {
#  description = "The count of shards for this Kinesis stream"
#  value       = aws_kinesis_stream.this[0].shard_count
#}

output "kinesis_stream_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Stream"
  value       = aws_kinesis_stream.this[0].arn
}

output "kinesis_stream_iam_policy_read_only_arn" {
  description = "The IAM Policy (ARN) read only of the Stream"
  value       = concat(aws_iam_policy.read-only.*.arn, [""])[0]
}

output "kinesis_stream_iam_policy_write_only_arn" {
  description = "The IAM Policy (ARN) write only of the Stream"
  value       = concat(aws_iam_policy.write-only.*.arn, [""])[0]
}

output "kinesis_stream_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the Stream"
  value       = concat(aws_iam_policy.admin.*.arn, [""])[0]
}