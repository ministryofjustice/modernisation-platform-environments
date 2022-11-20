variable "kinesis_source_stream_arn" {}

variable "kinesis_source_stream_name" {}

variable "name" {
    default = "kinesis-source"
}

variable "source_s3_id" {}

variable "source_s3_arn" {}

variable "aws_account_id" {}

variable "aws_region" {}

variable "cloudwatch_logging_enabled" {}

variable "cloudwatch_log_group_name" {}

variable "cloudwatch_log_stream_name" {}

variable "source_s3_kms" {}