variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "services" {
  description = "A list service names to create CodeDeploy applications and deployment groups for"
  type        = list(map(string))
}

variable "internal_alb_name" {
  description = "The name of the internal ALB"
  type        = string
}

variable "external_alb_name" {
  description = "The name of the external ALB"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "internal_listener_port" {
  description = "The port of the internal ALB listener"
  type        = number
  default     = 8080
}

variable "external_listener_port" {
  description = "The port of the external ALB listener"
  type        = number
  default     = 443
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "ec2_applications" {
  description = "List of application names for EC2 CodeDeploy deployments"
  type        = list(string)
  default     = []
}

variable "ec2_enabled" {
  description = "Enable EC2 deployments"
  type        = bool
  default     = false
}
