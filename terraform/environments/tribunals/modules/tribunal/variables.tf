variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "module_name" {
  type = string
  description = "Name of the module"
}

variable "app_db_name" {
  type = string
}

variable "app_db_login_name" {
}

variable "app_rds_url" {
}

variable "app_rds_password" {
  type = string
}

variable "environment" {
}

variable "support_team" {
  type = string
}

variable "support_email" {
  type = string
}

variable "curserver" {
  type = string
}

variable "tags" {
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

variable "documents_location" {
  type = string
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
}

variable "target_group_attachment_port" {
  type        = number
  description = "The port of the target group"
}

variable "target_group_arns" {
  description = "Map of target group ARNs"
  type        = map(string)
}

variable "target_group_arns_sftp" {
  description = "Map of target group ARNs for sftp"
  type        = map(string)
}

variable "new_db_password" {
  description = "Randomly generated password for each db"
}
