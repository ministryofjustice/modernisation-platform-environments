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

variable "ecs_service_internal_sg_id" {
  description = "The security group ID for internal ECS services"
  type        = string
}

variable "ecs_service_external_sg_id" {
  description = "The security group ID for external ECS services"
  type        = string
}

variable "esb_service_sg_id" {
  description = "Security Group ID for ESB"
  type        = string
}

variable "rds_cluster_security_group_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "private_ip" {
  description = "Private IP for the instance"
  type        = string
}