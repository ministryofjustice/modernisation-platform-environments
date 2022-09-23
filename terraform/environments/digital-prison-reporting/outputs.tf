output "s3_kms_arn" {
  description = "Amazon S3 Resource KmS KEY (ARN)"
  value       = aws_kms_key.s3.arn
}

output "kinesis_stream_name" {
  description = "The unique Stream name "
  value       = module.kinesis_stream_ingestor.kinesis_stream_name
}

output "kinesis_stream_shard_count" {
  description = "The count of Shards for this Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_shard_count
}

output "kinesis_stream_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_arn
}

output "kinesis_stream_iam_policy_read_only_arn" {
  description = "The IAM Policy (ARN) read only of the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_read_only_arn
}

output "kinesis_stream_iam_policy_write_only_arn" {
  description = "The IAM Policy (ARN) write only of the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_write_only_arn
}

#output "kinesis_stream_iam_policy_admin_arn" {
#  description = "The IAM Policy (ARN) admin of the Stream"
#  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
#}