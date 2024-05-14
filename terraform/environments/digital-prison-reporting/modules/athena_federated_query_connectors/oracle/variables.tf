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

variable "connection_string_nomis" {
  type        = string
  description = "The Athena Federated Query connection string for NOMIS (a JDBC connection string with an additional prefix)"
}

variable "nomis_cidr" {
  type        = string
  description = "CIDR that can be used to allow connectivity to NOMIS"
}
