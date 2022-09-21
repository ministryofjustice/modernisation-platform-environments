variable "name" {
  description = "A name to identify the stream. This is unique to the AWS account and region the Stream is created in."
  type        = string
}

variable "shard_count" {
  description = "The number of shards that the stream will use"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours. Minimum value is 24. Default is 24."
  type        = number
  default     = 24
}

variable "shard_level_metrics" {
  description = "A list of shard-level CloudWatch metrics which can be enabled for the stream."
  type        = list(string)
  default     = []
}

variable "enforce_consumer_deletion" {
  description = "A boolean that indicates all registered consumers should be deregistered from the stream so that the stream can be destroyed without error."
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "The encryption type to use. The only acceptable values are NONE or KMS."
  type        = string
  default     = "NONE"
}

variable "kms_key_id" {
  description = "The GUID for the customer-managed KMS key to use for encryption. You can also use a Kinesis-owned master key by specifying the alias alias/aws/kinesis."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}

variable "create_policy_read_only" {
  type        = bool
  default     = true
  description = "Whether to create IAM Policy (ARN) read only of the Stream"
}

variable "create_policy_write_only" {
  type        = bool
  default     = true
  description = "Whether to create IAM Policy (ARN) write only of the Stream"
}


variable "create_kinesis_stream" {
  type        = bool
  default     = false
  description = "Whether to create Kinesis Stream"
}

variable "create_policy_admin" {
  type        = bool
  default     = true
  description = "Whether to create IAM Policy (ARN) admin of the Stream"
}

variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}