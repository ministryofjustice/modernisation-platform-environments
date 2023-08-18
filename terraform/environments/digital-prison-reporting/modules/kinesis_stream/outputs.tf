output "kinesis_stream_name" {
  description = "The unique Kinesis stream name"
  value       = var.create_kinesis_stream ? try(aws_kinesis_stream.this[0].name, "") : null
}

#output "kinesis_stream_shard_count" {
#  description = "The count of shards for this Kinesis stream"
#  value       = var.create_kinesis_stream ? try(aws_kinesis_stream.this[0].shard_count, "") : null
#}

output "kinesis_stream_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Stream"
  value       = var.create_kinesis_stream ? try(aws_kinesis_stream.this[0].arn, "") : null
}

output "kinesis_stream_iam_policy_read_only_arn" {
  description = "The IAM Policy (ARN) read only of the Stream"
  value       = var.create_kinesis_stream ? try(concat(aws_iam_policy.read-only.*.arn, [""])[0], "") : null
}

output "kinesis_stream_iam_policy_write_only_arn" {
  description = "The IAM Policy (ARN) write only of the Stream"
  value       = var.create_kinesis_stream ? try(concat(aws_iam_policy.write-only.*.arn, [""])[0], "") : null
}

output "kinesis_stream_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the Stream"
  value       = var.create_kinesis_stream ? try(concat(aws_iam_policy.admin.*.arn, [""])[0], "") : null
}