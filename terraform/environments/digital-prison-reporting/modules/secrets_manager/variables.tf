variable "generate_random" {
  default     = false
  description = "Generate Random Secret ?"
  type        = bool
}

variable "description" {
  default     = ""
  description = "Description to add to Secret"
  type        = string
}

variable "kms_key_id" {
  default     = null
  description = "Optional. The KMS Key ID to encrypt the secret. KMS key arn or alias can be used."
}

variable "name" {
  default     = ""
  description = "Name (omit to use name_prefix)"
  type        = string
}

variable "name_prefix" {
  default     = "terraform"
  description = "Name Prefix (not used if name specified)"
  type        = string
}

variable "pass_version" {
  default     = 1
  description = "Password version. Increment this to trigger a new password."
  type        = number
}

variable "recovery_window_in_days" {
  default     = 30
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret."
  type        = number
}

variable "tags" {
  default     = {}
  description = "Tags to add to supported resources"
  type        = map(string)
}

########################################
# Secret Notification Rules
########################################

variable "cloudtrail_log_group" {
  # can't leave this blank or upstream module var validation will fail in tflint
  default     = "change_me"
  description = "Cloudtrail Log Group name (required if `enable_secret_access_notification=true`)"
  type        = string
}

variable "enable_secret_access_notification" {
  default     = false
  description = "Notify SNS topic on secret access (not recommended for most use cases)"
  type        = bool
}

variable "secret_access_metric_namespace" {
  default     = "SecretsManager"
  description = "Metric namespace to use for CloudWatch metric"
  type        = string
}

variable "secret_access_notification_arn" {
  default     = ""
  description = "SNS topic to notify on secret access (required if `enable_secret_access_notification=true`)"
  type        = string
}

########################################
# Complexity rules
########################################
variable "length" {
  description = "Length of string"
  type        = number
  default     = 10
}

variable "min_lower" {
  default     = 0
  description = "Minimum number of lower case characters"
  type        = number
}

variable "min_numeric" {
  default     = 0
  description = "Minimum number of numbers"
  type        = number
}

variable "min_special" {
  default     = 0
  description = "Minimum number of special characters"
  type        = number
}

variable "min_upper" {
  default     = 0
  description = "Minimum number of upper case characters"
  type        = number
}

variable "override_special" {
  type    = string
  default = ""
}

variable "use_lower" {
  default     = true
  description = "Use lower case  characters"
  type        = bool
}

variable "use_number" {
  default     = true
  description = "Use numbers"
  type        = bool
}

variable "use_special" {
  default     = true
  description = "Use special characters"
  type        = bool
}

variable "use_upper" {
  default     = true
  description = "Use upper case characters"
  type        = bool
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "(Optional) Map of Key Value Secrets, if Type set to KEY_VALUE"
}

variable "type" {
  type    = string
  default = "MONO"
}

variable "secret_value" {
  type        = string
  default     = ""
  description = "(Optional) Value if the type is set to MONO"
}

variable "ignore_secret_string" {
  description = "If to Ignore Local Secret Value changes"
  type        = bool
  default     = false
}