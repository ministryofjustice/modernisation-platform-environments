variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "module_name" {
  type        = string
  description = "Name of the module"
}

variable "environment" {
  type = string
}

variable "task_definition_volume" {
  type        = string
  description = "Name of the volume referenced in the sourceVolume parameter of container definition in the mountPoints section"
}

variable "appscaling_min_capacity" {
  type        = number
  description = "Minimum capacity of the application scaling target"
}

variable "appscaling_max_capacity" {
  type        = number
  description = "Maximum capacity of the application scaling target"
}

variable "ecs_scaling_cpu_threshold" {
  type        = number
  description = "The cpu threshold for ecs cluster scaling"
}

variable "ecs_scaling_mem_threshold" {
  type        = number
  description = "The utilised memory threshold for ec2 cluster scaling"
}

variable "app_count" {
  type        = string
  description = "Number of docker containers to run"
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
  description = "Name of the cluster"
}

variable "subnets_shared_public_ids" {
  type        = list(string)
  description = "Public subnets"
}

variable "tags" {
  description = "tags to apply to resources"
  type        = map(any)
  default     = {}
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
  type        = bool
}

variable "target_group_attachment_port" {
  description = "The port of the target group"
  type        = number
}

variable "target_group_attachment_port_sftp" {
  description = "The port of the target group for sftp"
  type        = number
}

variable "target_group_arns" {
  description = "Map of target group ARNs"
  type        = map(string)
}

variable "target_group_arns_sftp" {
  description = "Map of target group ARNs for sftp"
  type        = map(string)
}
