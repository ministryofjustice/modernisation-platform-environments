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

variable "yjsm_ec2_role" {
  description = "The IAM role name for the EC2 instance"
  type        = string
}

variable "yjsm_service" {
  description = "YJSM security group"
  type        = string
}