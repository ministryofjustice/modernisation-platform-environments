variable "alias" {
  description = "Alias name for the KMS key, without the 'alias/' prefix."
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail permitted to use this key."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is deleted."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
