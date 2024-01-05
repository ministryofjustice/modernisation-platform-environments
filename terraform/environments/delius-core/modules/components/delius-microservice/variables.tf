variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "name" {
  description = "Name of the application"
  type        = string
}

variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}


variable "rds_license_model" {
  description = "RDS license model to use"
  type        = string
  default     = "license-included"
}

variable "rds_engine" {
  description = "RDS engine to use"
  type        = string
}

variable "rds_engine_version" {
  description = "RDS engine version to use"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class to use"
  type        = string
}

variable "rds_username" {
  description = "RDS database username"
  type        = string
}

variable "snapshot_identifier" {
  description = "RDS snapshot identifier"
  type        = string
  default     = null
}

variable "rds_parameter_group_name" {
  description = "RDS parameter group name"
  type        = string
  default     = null
}

variable "rds_deletion_protection" {
  description = "RDS deletion protection"
  type        = bool
  default     = false
}

variable "rds_delete_automated_backups" {
  description = "RDS delete automated backups"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "RDS skip final snapshot"
  type        = bool
  default     = false
}

variable "rds_port" {
  description = "RDS port"
  type        = number
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = null
}

variable "rds_max_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = null
}

variable "rds_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp2"
}

variable "maintenance_window" {
  description = "RDS/elasticache maintenance window"
  type        = string
  default     = "mon:03:00-mon:04:00"
}

variable "rds_auto_major_version_upgrade" {
  description = "RDS auto major version upgrade"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "00:00-03:00"
}

variable "rds_iam_database_authentication_enabled" {
  description = "RDS iam database authentication enabled"
  type        = bool
  default     = false
}

variable "rds_multi_az" {
  description = "RDS multi az"
  type        = bool
  default     = false
}

variable "rds_monitoring_interval" {
  description = "RDS monitoring interval"
  type        = number
  default     = 60
}

variable "rds_performance_insights_enabled" {
  description = "RDS performance insights enabled"
  type        = bool
  default     = false
}

variable "rds_enabled_cloudwatch_logs_exports" {
  description = "RDS enabled cloudwatch logs exports"
  type        = list(string)
}

variable "ingress_security_groups" {
  description = "Additional RDS/elasticache ingress security groups"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}


variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "health_check_grace_period_seconds" {
  description = "The amount of time, in seconds, that Amazon ECS waits before unhealthy instances are shut down."
  type        = number
  default     = 60
}

variable "ecs_service_port" {
  description = "The port on which the ECS service is exposing the container"
  type        = number
  default     = 443
}

variable "task_def_container_port" {
  description = "The port on which the container is exposing the application"
  type        = number
  default     = 8080
}

variable "target_group_protocol" {
  description = "The protocol to use for the target group"
  type        = string
  default     = "HTTP"
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for the target group"
  type        = string
}

variable "microservice_lb_arn" {
  description = "The ARN of the load balancer to use for the target group"
  type        = string
}

variable "create_rds" {
  description = "Whether to create an RDS instance"
  type        = bool
  default     = false
}

variable "create_elasticache" {
  description = "Whether to create an Elasticache instance"
  type        = bool
  default     = false
}

variable "elasticache_node_type" {
  description = "The Elasticache node type"
  type        = string
  default     = "cache.m4.large"
}

variable "elasticache_engine" {
  description = "The Elasticache engine"
  type        = string
  default     = "redis"
}

variable "elasticache_engine_version" {
  description = "The Elasticache engine version"
  type        = string
  default     = "5.0.6"
}

variable "elasticache_port" {
  description = "The Elasticache port"
  type        = number
  default     = 6379
}

variable "elasticache_parameter_group_name" {
  description = "The Elasticache parameter group name"
  type        = string
  default     = "default.redis5.0"
}

variable "elasticache_subnet_group_name" {
  description = "The Elasticache subnet group name"
  type        = string
  default     = "default"
}
variable "elasticache_num_cache_nodes" {
  description = "The Elasticache number of cache nodes"
  type        = number
  default     = 1
}

variable "container_environment_vars" {
  description = "Environment variables to pass to the container"
  type        = map(string)
}
variable "container_secrets" {
  description = "Secrets to pass to the container"
  type        = map(string)
}
variable "container_port_mappings" {
  description = "Port mappings to pass to the container"
  type = list(object({
    container_port = number
    host_port      = number
    protocol       = string
  }))
}