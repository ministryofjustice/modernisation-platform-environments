variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "name" {
  description = "The name of the Aurora cluster"
  type        = string
}

variable "engine" {
  description = "The database engine to use for the Aurora cluster"
  type        = string
}

variable "engine_version" {
  description = "The version of the database engine to use for the Aurora cluster"
  type        = string
}

variable "db_cluster_instance_class" {
  description = "The instance class for the Aurora cluster"
  type        = string
}

variable "rds_security_group_ingress" {
  description = "List of ingress rules for the RDS security group"
  type = map(object({
    from_port                = optional(number, null)
    to_port                  = optional(number, null)
    protocol                 = string
    cidr_blocks              = optional(list(string), null)
    source_security_group_id = optional(string, null)
    description              = string
  }))
}

variable "storage_type" {
  description = "The storage type of the RDS instance"
  type        = string
  default     = null
}

variable "iops" {
  description = "The amount of provisioned IOPS"
  type        = number
  default     = null
}

variable "allocated_storage" {
  description = "The amount of storage to allocate to the RDS instance"
  type        = number
  default     = null
}

variable "azs" {
  description = "The availability zones to deploy the RDS instance"
  type        = list(string)
}

variable "database_subnet_group_name" {
  description = "The name of the database subnet group"
  type        = string
}

variable "master_username" {
  description = "The master username for the RDS instance"
  type        = string
  default     = "postgres"
}

## Scheduler
variable "create_sheduler" {
  description = "Create scheduler for Aurora cluster"
  type        = bool
  default     = true
}

variable "start_aurora_cluster_schedule" {
  description = "The schedule for starting the Aurora cluster"
  type        = string
  default     = "cron(00 06 ? * MON-FRI *)"
}

variable "stop_aurora_cluster_schedule" {
  description = "The schedule for stopping the Aurora cluster"
  type        = string
  default     = "cron(00 19 ? * MON-FRI *)"
}

variable "database_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

variable "iam_roles" {
  description = "Map of IAM roles and supported feature names to associate with the cluster"
  type        = map(map(string))
  default     = {}
}

variable "instances" {
  description = "Map of cluster instances and any specific/overriding attributes to be created"
  type        = any
  default = {
    "db-1" = {
    },
    "db-2" = {
    }
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur, in (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not"
  type        = bool
  default     = null
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting the RDS instance"
  type        = bool
  default     = true
}

variable "snapshot_identifier" {
  description = "The snapshot identifier to restore from if required."
  type        = string
  default     = null
}

variable "user_passwords_to_reset_rotated" {
  description = "List of user passwords to reset with secret rotation function"
  type        = list(string)
  default     = []
}

variable "user_passwords_to_reset_static" {
  description = "List of user passwords to reset without a secret rotation function"
  type        = list(string)
  default     = []
}

variable "alb_route53_record_zone_id" {
  description = "The zone id to create the route53 record in"
  type        = string
  default     = ""
}

variable "alb_route53_record_name" {
  description = "If you want to add a route53 record for the ALB set this and set the zone id"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
  default     = null
}

variable "db_name" {
  description = "The name of the database mapped to the RDS instance, used in secret creation"
  type        = string
  default     = "yjafrds01"
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}
