variable "app_name" {
  description = "Name of the application"
}

variable "module_name" {
  description = "Name of the module"
}

variable "app_url" {
}

variable "sql_migration_path" {
}

variable "app_db_name" {
}

variable "app_db_login_name" {
}

variable "app_source_db_name" {
}

variable "app_rds_url" {
}

variable "app_rds_user" {
}

variable "app_rds_port" {
}

variable "app_rds_password" {
}

variable "app_source_db_url" {
}

variable "app_source_db_user" {
}

variable "app_source_db_password" {
}

variable "app_load_balancer" {
}

variable "environment" {
}

variable "application_data" {
}

variable "tags" {
}

variable "dms_instance_arn" {
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

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
}

variable "waf_arn" {
}

variable "target_group_attachment_port" {
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

variable "db_role_name" {
  description = "Lambda role name"
}

variable "db_role_arn" {
  description = "Lambda role arn"
}