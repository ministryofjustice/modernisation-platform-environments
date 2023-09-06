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

variable "buffering_interval" {
  description = "Buffer incoming data for the specified period of time, in seconds between 60 to 900, before delivering it to S3."
}

variable "database_name" {
  description = "Specifies the name of the AWS Glue database that contains the schema for the output data"
}

variable "table_name" {
  description = "Specifies the AWS Glue table that contains the column information that constitutes your data schema."
}