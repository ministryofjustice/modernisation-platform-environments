variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "service_arn" {
  description = "The ARN of the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "task_count" {
  description = "The desired task count for the ECS service"
  type        = number
}