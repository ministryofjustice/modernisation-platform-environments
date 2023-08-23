variable "kinesis_source_stream_arn" {}

variable "kinesis_source_stream_name" {}

variable "name" {
  default = "kinesis-stream"
}

variable "target_s3_id" {}

variable "target_s3_arn" {}

variable "aws_account_id" {}

variable "aws_region" {}

variable "cloudwatch_logging_enabled" {}

variable "cloudwatch_log_group_name" {}

variable "cloudwatch_log_stream_name" {}

variable "target_s3_kms" {}

variable "target_s3_error_prefix" {
  description = "S3 Error Prefix Key"
  default     = null
}

variable "target_s3_prefix" {
  description = "S3 Prefix Key"
  default     = null
}

variable "buffering_size" {
  description = "Buffer incoming data to the specified size, in MBs, before delivering it to S3."
}