variable "app_name" {
  description = "Name of the application"
}

variable "module_name" {
  description = "Name of the module"
}

variable "app_url" {
}

variable "app_db_name" {
}

variable "app_db_login_name" {
}

variable "app_rds_url" {
}

variable "app_rds_user" {
}

variable "app_rds_port" {
}

variable "app_rds_password" {
}

variable "environment" {
}

variable "application_data" {
  type = object({
    accounts = map(object({
      allocated_storage         = string
      storage_type             = string
      db_identifier            = string
      engine                   = string
      engine_version           = string
      instance_class           = string
      username                 = string
      curserver               = string
      support_team            = string
      support_email           = string
      server_port_1           = string
      task_definition_volume  = string
      server_port             = number
      app_count               = number
      appscaling_min_capacity = number
      appscaling_max_capacity = number
      ecs_scaling_cpu_threshold = number
      ecs_scaling_mem_threshold = number
    }))
  })
  description = "Application configuration data from application_variables.json"
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
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
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

variable "new_db_password" {
  description = "Randomly generated password for each db"
}
