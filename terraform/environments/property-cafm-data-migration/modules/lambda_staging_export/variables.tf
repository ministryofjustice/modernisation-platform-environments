variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Lambda to export the CAFM data to the staging area in S3 as CSV files."
  type        = string
  default     = ""
}

variable "s3_output_path" {
  description = "S3 URI prefix for CSV output (e.g. s3://bucket/prefix)"
  type        = string
}

variable "s3_output_bucket_arn" {
  description = "ARN of the S3 bucket used for CSV output"
  type        = string
}

variable "s3_athena_results_bucket_arn" {
  description = "ARN of the S3 bucket used for Athena query results"
  type        = string
}

variable "s3_athena_results_path" {
  description = "S3 URI for Athena query results (e.g. s3://bucket/athena-results)"
  type        = string
}

variable "s3_source_bucket_arns" {
  description = "ARNs of source S3 buckets and prefixes Athena reads from (bucket ARN and bucket/*)"
  type        = list(string)
}

variable "source_database" {
  description = "Glue catalogue database the Lambda queries (used as the DATABASE env var)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  type        = string
}

variable "additional_database_names" {
  description = "Glue database names the Lambda role needs IAM and Lake Formation access to (includes the source database and any databases its views resolve through)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
