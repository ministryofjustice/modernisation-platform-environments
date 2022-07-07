variable "topic_display_name" {
  description = "The display name of your SNS Topic. MUST BE UNDER 10 CHARS"
  type        = string
}


variable "aws_region" {
  description = "Region into which the resource will be created"
  default     = "eu-west-2"
  type        = string
}

variable "application" {
  description = "Application name using the topic"
  default     = "nomis"
  type        = string
}

variable "env" {
  description = "Target environment (test/prod)"
  default     = "test"
  type        = string
}

variable "kms_master_key_id" {
  description = "Id of the customer managed key used to encrypt this topic"
  type        = string
}

variable "kms_master_key_arn" {
  description = "ARN of the customer managed key used to encrypt this topic"
  type        = string
}