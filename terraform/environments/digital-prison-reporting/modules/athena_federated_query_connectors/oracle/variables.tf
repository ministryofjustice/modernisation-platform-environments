variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "project_prefix" {
  type        = string
  description = "Prefix identifying the project"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "VPC Subnet ID"
}

variable "connector_jar_bucket_name" {
  type        = string
  description = "The name of the S3 bucket that contains the Connector JAR"
}

variable "connector_jar_bucket_key" {
  type        = string
  description = "The name of the S3 bucket that contains the Connector JAR"
}

variable "spill_bucket_name" {
  type        = string
  description = "The name of the S3 bucket to use for writing data that spills from the Connector Lambda's memory"
}

variable "spill_bucket_prefix" {
  type        = string
  default     = "athena-spill"
  description = "The key prefix in the spill S3 bucket to use for writing data that spills from the Connector Lambda's memory"
}

variable "nomis_credentials_secret_arn" {
  type        = string
  description = "The ARN of the Secret Manager secret containing NOMIS credentials"
}

variable "connection_strings" {
  type        = map(string)
  description = "A map of the catalog name to Athena Federated Query connection strings. Cannot be empty. The 1st element will be the default connection string for the connector."
  # E.g. The following will configure the my_catalog catalog to use the provided connection string
  # connection_strings {
  #     my_catalog = "oracle:jdbc:...."
  # }
}

variable "lambda_memory_allocation_mb" {
  type        = number
  default     = 3000
  description = "Amount of memory in MB the Connector Lambda Function can use at runtime"
}

variable "lambda_timeout_seconds" {
  type        = number
  default     = 900
  description = "Limit of time the Connector lambda has to run in seconds."
}

variable "lambda_reserved_concurrent_executions" {
  type        = number
  description = "Amount of reserved concurrent executions for the Connector lambda function. A value of 0 disables the lambda from being triggered and -1 removes any concurrency limitations"
}
