variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "environment" {
  description = "The environment for the ECS cluster"
  type        = string
}

variable "nameserver" {
  description = "The nameserver for the ECS cluster, normally ends in .0.2"
  type        = string
}

variable "ec2_ami_id" {
  description = "The AMI ID for the ECS cluster"
  type        = string
  default     = ""
}

variable "ecs_services" {
  description = "A list of ECS services to create. Will create the main container definition for the app itself"
  type = map(object({
    name                     = string
    image                    = string
    container_port           = optional(number, 8080)
    deployment_controller    = optional(string, "CODE_DEPLOY")
    internal_only            = optional(bool, true)
    additional_port_mappings = optional(any, [])
    enable_healthcheck       = optional(bool, true)
    health_check = optional(object({
      command      = list(string)
      interval     = number
      timeout      = number
      retries      = number
      start_period = number
      }), {
      command      = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
      interval     = 30
      timeout      = 5
      retries      = 10
      start_period = 60
    })
    desired_count                          = optional(number, 2)
    autoscaling_min_capacity               = optional(number, 2)
    autoscaling_max_capacity               = optional(number, 4)
    health_check_grace_period_seconds      = optional(number, 360)
    stop_timeout                           = optional(number, 30)
    deployment_minimum_healthy_percent     = optional(number, 100)
    deployment_maximum_percent             = optional(number, 200)
    task_cpu                               = optional(number)
    task_memory                            = optional(number)
    container_cpu                          = optional(number, null)
    container_memory                       = optional(number, null)
    command                                = optional(list(string), [])
    entry_point                            = optional(list(string), [])
    readonly_root_filesystem               = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 400)
    additional_mount_points = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = bool
    })), [])
    volumes = optional(list(object({
      name = string
      host = optional(map(any))
    })), [])
    additional_environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    enable_postgres_secret         = optional(bool, false) #change to true once we have the secret ready
    dependencies                   = optional(list(string), null)
    ecs_task_iam_role_name         = optional(string, null)
    load_balancer_target_group_arn = optional(string, null)
    additional_container_definitions = optional(map(object({ #must define all the container def stuff again here otherwise terraform just wont pull it in and ignore it
      name          = string
      image         = string
      port_mappings = optional(list(object({})), [])
      entryPoint    = optional(list(string), [])
      command       = optional(list(string), [])
      cpu           = optional(number)
      memory        = optional(number)
      log_configuration = optional(object({
        logDriver = optional(string)
        options   = optional(map(string))
      }), null)
      readonly_root_filesystem = optional(bool, false)
      mount_points = optional(list(object({
        sourceVolume  = string
        containerPath = string
        readOnly      = bool
      })), [])
      volumes = optional(list(object({
        name = string
        host = optional(map(any))
      })), [])
      environment = optional(list(object({
        name  = string
        value = string
      })), [])
    })), {}) #"Additional container definitions to add to the standard container definition for ECS services"
    tags = optional(map(string), null)
  }))
}

variable "get_postgres_secret" {
  description = "will any of the services use the postgres secret?"
  type        = bool
  default     = false
}

variable "ecs_service_postgres_secret_arn" {
  description = "The ARN of the postgres secret used by ecs services"
  type        = string
  default     = ""
}

variable "ecs_subnet_ids" {
  description = "A list of subnet IDs to use for ECS services"
  type        = list(string)
}

variable "service_discovery_namespace" {
  description = "The name of the service discovery namespace"
  type        = string
  default     = ""
}

variable "additional_ecs_common_security_group_ingress" {
  description = "List of ingress rules for the common ecs security group"
  type = list(object({
    from_port              = number
    to_port                = number
    protocol               = string
    cidr_blocks            = optional(list(string), null)
    source_security_groups = optional(list(string), null)
    description            = string
  }))
  default = []
}

variable "ec2_ingress_with_source_security_group_id_rules" {
  description = "List of ingress rules for the EC2 security group"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
    description              = string
  }))
  default = []
}

variable "disable_overnight_scheduler" {
  description = "disable the overnight scheduler"
  type        = bool
  default     = false
}

variable "morning_cron_schedule" {
  description = "The cron schedule for the morning scheduler"
  type        = string
  default     = "0 6 * * 1-5"
}

variable "overnight_cron_schedule" {
  description = "The cron schedule for the overnight scheduler"
  type        = string
  default     = "0 19 * * 1-5"
}

variable "ec2_instance_type" {
  description = "The instance type for the ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "ec2_min_size" {
  description = "The minimum number of EC2 instances in the ECS cluster"
  type        = number
  default     = 1
}

variable "ec2_max_size" {
  description = "The maximum number of EC2 instances in the ECS cluster"
  type        = number
  default     = 2
}

variable "ec2_desired_capacity" {
  description = "The desired number of EC2 instances in the ECS cluster"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "internal_alb_security_group_id" {
  description = "The security group ID for the ALB"
  type        = string
}

variable "external_alb_security_group_id" {
  description = "The security group ID for the external ALB"
  type        = string
}

variable "external_alb_arn" {
  description = "The ARN of the external ALB"
  type        = string
}

variable "internal_alb_arn" {
  description = "The ARN of the internal ALB"
  type        = string
}

variable "internal_alb_name" {
  description = "The name of the internal ALB"
  type        = string
}

variable "external_alb_name" {
  description = "The name of the external ALB"
  type        = string
}

variable "cloudfront_ingress" {
  description = "List of ingress rules for the cloudfront security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = list(string)
    description     = string
  }))
  default = []
}

variable "ecs_common_security_group_ingress" {
  description = "List of ingress rules for the common ecs security group"
  type = list(object({
    from_port              = number
    to_port                = number
    protocol               = string
    cidr_blocks            = optional(list(string), null)
    source_security_groups = optional(list(string), null)
    description            = string
  }))
  default = []
}

variable "spot_overrides" {
  description = "A list of spot instance overrides"
  type = list(object({
    instance_type     = string
    weighted_capacity = string
  }))
  default = []
}

variable "ecs_allowed_secret_arns" {
  description = "A list of allowed secret ARNs"
  type        = list(string)
  default     = []
}


variable "rds_postgresql_sg_id" {
  description = "The ID of the security group that controlls ingress to the PostgreSQL database."
  type        = string
}

variable "redshift_sg_id" {
  description = "The ID of the security group that controlls ingress to the Redshift database."
  type        = string
}

variable "ecs_secrets_access_policy_secret_arns" {
  description = "A list of secret ARNs to allow access to"
  type        = string
}

variable "ecs_role_additional_policies_arns" {
  description = "A list of additional policies to attach to the ECS task role"
  type        = list(string)
  default     = []
}

variable "secret_kms_key_arn" {
  description = "The ARN of the KMS key to use for secrets"
  type        = string
}

variable "list_of_target_group_arns" {
  description = "A list of target group ARNs to use for the ECS services. The key must match the name of the ecs service to be picked up"
  type        = map(string)
  default     = {}
}
