variable "app_name" {
  description = "Name of the application"
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

variable "documents_location"{
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
}

variable "waf_arn" {
}