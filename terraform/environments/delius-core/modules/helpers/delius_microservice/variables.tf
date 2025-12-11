variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "name" {
  description = "Name of the application"
  type        = string
}


variable "namespace" {
  description = "Namespace of the application"
  type        = string
  default     = "delius-core"
}


variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group id for the cluster"
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
  default     = null
}

variable "rds_endpoint_environment_variable" {
  description = "Environment variable to store the RDS endpoint"
  type        = string
  default     = ""
}

variable "rds_password_secret_variable" {
  description = "Secret variable to store the rds secretsmanager arn password"
  type        = string
  default     = ""
}

variable "rds_user_secret_variable" {
  description = "Secret variable to store the rds secretsmanager arn username"
  type        = string
  default     = ""
}

variable "rds_engine_version" {
  description = "RDS engine version to use"
  type        = string
  default     = null
}

variable "rds_instance_class" {
  description = "RDS instance class to use"
  type        = string
  default     = null
}

variable "rds_username" {
  description = "RDS database username"
  type        = string
  default     = null
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
  default     = null
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
  default     = "Wed:21:00-Wed:23:00"
}

variable "rds_allow_major_version_upgrade" {
  description = "RDS allow major version upgrade"
  type        = bool
  default     = false
}

variable "rds_apply_immediately" {
  description = "RDS apply immediately"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period"
  type        = number
  default     = 1
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "19:00-21:00"
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
  default     = null
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

variable "db_ingress_security_groups" {
  description = "Additional RDS/elasticache ingress security groups"
  type        = list(string)
  default     = []
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

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "container_port_config" {
  description = "The port configuration for the container. First in list is used for Load Balancer Configuration"
  type = list(object({
    containerPort = number
    protocol      = string
  }))
}

variable "target_group_protocol" {
  description = "The protocol to use for the target group"
  type        = string
  default     = "HTTP"
}

variable "target_group_protocol_version" {
  description = "The version of the protocol to use for the target group"
  type        = string
  default     = "HTTP2"
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for the target group"
  type        = string
  default     = null
}

variable "microservice_lb" {
  description = "load balancer to use for the target group"
  type        = any
  default     = null
}

variable "microservice_lb_https_listener_arn" {
  description = "The ARN of the load balancer HTTPS listener to use for the target group"
  type        = string
  default     = null
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

variable "elasticache_apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "elasticache_endpoint_environment_variable" {
  description = "Environment variable to store the elasticache endpoint"
  type        = string
  default     = ""
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

variable "elasticache_num_cache_nodes" {
  description = "The Elasticache number of cache nodes"
  type        = number
  default     = 1
}

variable "elasticache_parameter_group_family" {
  description = "The Elasticache parameter group family"
  type        = string
  default     = "redis5.0"
}

variable "elasticache_parameters" {
  description = "A map of elasticache parameter names & values"
  type        = map(string)
  default     = {}
}

variable "elasticache_password_secret_variable" {
  description = "Secret variable to store the elasticache secretsmanager arn password"
  type        = string
  default     = ""
}

variable "elasticache_user_variable" {
  description = "variable to store the elasticache username"
  type        = string
  default     = ""
}

variable "container_vars_default" {
  description = "Environment variables to pass to the container"
  type        = map(any)
}

variable "container_vars_env_specific" {
  description = "Environment variables to pass to the container"
  type        = map(any)
}

variable "container_secrets_default" {
  description = "Secrets to pass to the container"
  type        = map(any)
}

variable "container_secrets_env_specific" {
  description = "Secrets to pass to the container"
  type        = map(any)
}

variable "alb_security_group_id" {
  description = "The security group ID of the ALB"
  type        = string
  default     = null
}

variable "alb_stickiness_enabled" {
  description = "Enable or disable stickiness"
  type        = string
  default     = true
}

variable "alb_stickiness_type" {
  description = "Type of stickiness for the alb target group"
  type        = string
  default     = "lb_cookie"
}

variable "alb_listener_rule_priority" {
  description = "Priority of the alb listener"
  type        = number
  default     = null
}

variable "alb_listener_rule_paths" {
  description = "Paths to use for the alb listener rule"
  type        = list(string)
  default     = null
}


variable "alb_listener_rule_host_header" {
  description = "Host header to use for the alb listener rule"
  type        = string
  default     = null
}

variable "cloudwatch_error_pattern" {
  description = "The cloudwatch error pattern to use for the alarm"
  type        = string
  default     = "/error/"
}

variable "container_image" {
  description = "The container image to use"
  type        = string
}

variable "container_memory" {
  description = "The container memory to use"
  type        = number
  default     = 1024
}

variable "container_cpu" {
  description = "The container cpu to use"
  type        = number
  default     = 512
}

variable "bastion_sg_id" {
  description = "Security group id of the bastion"
  type        = string
}


variable "create_service_nlb" {
  description = "Whether to create a service NLB"
  type        = bool
  default     = false
}

variable "desired_count" {
  description = "The desired count of the service"
  type        = number
  default     = 1
}

variable "efs_volumes" {
  description = "The EFS volumes to mount"
  type        = list(any)
  default     = []
}

variable "mount_points" {
  description = "The mount points for the EFS volumes"
  type        = list(any)
  default     = []
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 0
}

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 100
}

variable "ignore_changes_service_task_definition" {
  description = "Ignore changes to the task definition"
  type        = bool
  default     = true
}

variable "redeploy_on_apply" {
  description = "Redeploy the ecs service on apply"
  type        = bool
  default     = false
}

variable "ecs_service_ingress_security_group_ids" {
  description = "Security group ids to allow ingress to the ECS service"
  type = list(object({
    referenced_security_group_id = optional(string, null)
    cidr_ipv4                    = optional(string, null)
    description                  = optional(string, null)
    port                         = number
    ip_protocol                  = string
  }))
  default = []
}

variable "ecs_service_egress_security_group_ids" {
  description = "Security group ids to allow egress from the ECS service"
  type = list(object({
    referenced_security_group_id = optional(string, null)
    cidr_ipv4                    = optional(string, null)
    port                         = optional(number, null)
    description                  = optional(string, null)
    ip_protocol                  = string
  }))
  default = []
}

variable "log_error_pattern" {
  description = "Used by metric filter for error count"
  type        = string
}

variable "log_error_threshold_config" {
  description = "Used by log error alarms"
  type = map(object({
    threshold = number
    period    = number
  }))
  default = {
    warning = {
      threshold = 5
      period    = 120
    }
    critical = {
      threshold = 10
      period    = 300
    }
  }
}

variable "ecs_monitoring_anomaly_detection_thresholds" {
  description = "The threshold for the anomaly detection"
  type        = map(number)
  default = {
    memory = 5
    cpu    = 5
  }
}

variable "ecs_monitoring_running_tasks_less_than_desired_period" {
  description = "The period for the running tasks less than desired alarm"
  type        = number
  default     = 60
}

variable "sns_topic_arn" {
  description = "Used by alarms"
  type        = string
}

variable "frontend_lb_arn_suffix" {
  description = "Used by alarms"
  type        = string
  default     = ""
}

variable "extra_task_role_policies" {
  description = "A map of data \"aws_iam_policy_document\" objects, keyed by name, to attach to the task role"
  type        = map(any)
  default     = {}
}

variable "extra_task_exec_role_policies" {
  description = "A map of data \"aws_iam_policy_document\" objects, keyed by name, to attach to the task exec role"
  type        = map(any)
  default     = {}
}

variable "container_health_check" {
  description = "The health check configuration for the container"
  type = object({
    command     = list(string)
    interval    = number
    timeout     = number
    retries     = number
    startPeriod = number
  })
  default = null
}

variable "alb_health_check" {
  description = "The health check configuration for the ALB"
  type = object({
    path                 = string
    interval             = number
    timeout              = number
    healthy_threshold    = number
    unhealthy_threshold  = number
    matcher              = string
    protocol             = string
    grace_period_seconds = number
  })
  default = {
    path                 = "/"
    interval             = 30
    timeout              = 5
    healthy_threshold    = 5
    unhealthy_threshold  = 5
    matcher              = "200-499"
    protocol             = "HTTP"
    grace_period_seconds = 120
  }
}

variable "nlb_ingress_security_group_ids" {
  description = "Security group ids to allow ingress to the ECS service"
  type = list(object({
    referenced_security_group_id = optional(string, null)
    cidr_ipv4                    = optional(string, null)
    description                  = optional(string, null)
    port                         = number
    ip_protocol                  = string
  }))
  default = []
}

variable "nlb_egress_security_group_ids" {
  description = "Security group ids to allow egress from the ECS service"
  type = list(object({
    referenced_security_group_id = optional(string, null)
    cidr_ipv4                    = optional(string, null)
    port                         = optional(number, null)
    description                  = optional(string, null)
    ip_protocol                  = string
  }))
  default = []
}

variable "system_controls" {
  description = "The system controls for the container"
  type        = list(any)
  default     = []
}

variable "pin_task_definition_revision" {
  type        = number
  description = "The revision of the task definition to use"
  default     = 0
}

variable "log_retention" {
  type        = number
  description = "Number of days to retain the logs"
  default     = 7
}
