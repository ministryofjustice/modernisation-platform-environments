variable "name_prefix" {
  type        = string
  description = "(Required) Name that will be used for identify resources."
}

variable "create_bucket" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS S3 Bucket"
}

variable "aws_kms_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}