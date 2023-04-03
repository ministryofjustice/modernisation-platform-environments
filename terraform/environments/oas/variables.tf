variable "iam_role_arn" {
  default     = "arn:aws:iam::711138931639:role/AWSBackup"
  description = "IAM role ARN for the AWS Backup service role"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to apply to resources, where applicable"
  type        = map(any)
}