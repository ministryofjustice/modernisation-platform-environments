variable "app_name" {
  description = "Name of the application"
}

variable "module_name" {
  description = "Name of the module"
}

variable "app_url" {
}

variable "environment" {
}

variable "task_definition_volume" {
}

variable "appscaling_min_capacity" {
}

variable "appscaling_max_capacity" {
}

variable "ecs_scaling_cpu_threshold" {
}

variable "ecs_scaling_mem_threshold" {
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
}

variable "cluster_name" {
}

variable "subnets_shared_public_ids" {
}

variable "aws_acm_certificate_external" {
}

variable "vpc_shared_id" {
}

variable "documents_location" {
}

variable "application_data" {
}

variable "tags" {
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
}

variable "waf_arn" {
}

variable "target_group_attachment_port" {
  description = "The port of the target group"
}

variable "target_group_attachment_port_sftp" {
  description = "The port of the target group for sftp"
}

variable "app_load_balancer" {
}

variable "target_group_arns_sftp" {
  description = "Map of target group ARNs for sftp"
  type        = map(string)
}