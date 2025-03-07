variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment_name" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "database_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

## 
variable "rds_secret_rotation_arn" {
  description = "The ARN of the rotated postgres secret."
  type        = string
}

