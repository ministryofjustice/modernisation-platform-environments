variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
}

#variable "setup_vpc_endpoint" {
#  type        = bool
#  default     = false
#  description = "(Optional) Create VPC Endpoint, If Set to Yes"
#}

variable "tags" {
  description = "Additional tags to apply to the log group."
  type        = map(any)
  default     = {}
}

variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "An List of VPC SGroups"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "Current AWS VPC ID."
  default     = ""
}
