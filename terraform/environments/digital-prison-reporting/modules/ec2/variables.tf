variable "name" {
  description = "The EC2 Sec name."
}

variable "description" {
  type        = string
  default     = ""
  description = "(Optional) Description"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "vpc" {}

variable "ec2_sec_rules" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "ec2_sec_rules" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}