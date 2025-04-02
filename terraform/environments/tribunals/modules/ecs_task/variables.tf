variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "task_definition_volume" {
  type        = string
  description = "Name of the volume referenced in the sourceVolume parameter of container definition in the mountPoints section"
}

variable "container_definition" {
  type        = string
  description = "Container definition to be used by the ECS service"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "appscaling_min_capacity" {
  type        = number
  description = "Minimum capacity of the application scaling target"
  default     = 1
}

variable "appscaling_max_capacity" {
  type        = number
  description = "Maximum capacity of the application scaling target"
  default     = 4
}

variable "ecs_scaling_cpu_threshold" {
  type        = string
  description = "The cpu threshold for ecs cluster scaling"
}

variable "ecs_scaling_mem_threshold" {
  type        = string
  description = "The utilised memory threshold for ec2 cluster scaling"
}

variable "app_count" {
  type        = string
  description = "Number of docker containers to run"
}

variable "lb_tg_arn" {
  type        = string
  description = "Load balancer target group ARN used by ECS service"
}

variable "server_port" {
  type        = string
  description = "The port the containers will be listening on"
}

variable "cluster_id" {
  type        = string
  description = "The ID of the ECS cluster"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster"
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
  type        = bool
}

variable "sftp_lb_tg_arn" {
  type        = string
  description = "Network Load balancer target group ARN used by SFTP connections"
}
