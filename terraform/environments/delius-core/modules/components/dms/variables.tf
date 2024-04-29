
variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "instance_class" {
  description = "instance class to use for dms"
  type        = string
  default     = "dms.t3.micro"
}

variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}
