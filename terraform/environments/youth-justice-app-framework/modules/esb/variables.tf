variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}


variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "environment" {
  description = "The environment for the ECS cluster"
  type        = string
}

variable "yjsm_service_sg_id" {
  description = "Security Group ID for ESB"
  type        = string
}