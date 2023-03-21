variable "identifier" {
  type        = string
  description = "The identifier of the resource"
}

variable "region" {
  type        = string
  description = "Destination AWS Region for the infrastructure"
  default     = "eu-west-2"
}

variable "availability_zone" {
  type        = string
  description = "The availability zone in which to deploy the infrastructure"
  default     = "eu-west-2a"
  nullable    = false
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "instance" {
  description = "RDS instance settings, see db_instance documentation"
  type = object({
    create                              = optional(bool, true)
    allocated_storage                   = number
    storage_type                        = optional(string, "gp2")
    storage_encrypted                   = optional(bool, false)
    kms_key_id                          = optional(string)
    replicate_source_db                 = optional(string)
    snapshot_identifier                 = optional(string)
    allow_major_version_upgrade         = optional(bool, false)
    apply_immediately                   = optional(bool, false)
    auto_minor_version_upgrade          = optional(bool, false)
    license_model                       = optional(string)
    iam_database_authentication_enabled = optional(bool, false)
    db_name                             = optional(string)
    engine                              = string
    engine_version                      = optional(string)
    instance_class                      = string
    username                            = string
    password                            = string
    parameter_group_name                = optional(string)
    skip_final_snapshot                 = optional(bool, false)
    max_allocated_storage               = optional(number)
    port                                = optional(string)
    final_snapshot_identifier           = optional(bool, false)
    vpc_security_group_ids              = optional(list(string))
    db_subnet_group_name                = optional(string)
    multi_az                            = optional(bool, false)
    iops                                = optional(number, 0)
    publicly_accessible                 = optional(bool, false)
    monitoring_interval                 = optional(number, 0)
    monitoring_role_arn                 = optional(string)
    maintenance_window                  = optional(string)
    copy_tags_to_snapshot               = optional(bool, false)
    backup_retention_period             = optional(number, 1)
    backup_window                       = optional(string)
    character_set_name                  = optional(string)
    option_group_name                   = optional(string)
    enabled_cloudwatch_logs_exports     = optional(list(string))
  })
}

variable "instance_automated_backups_replication" {
  type    = number
  default = 14
}

variable "option_group" {
  description = "RDS instance option group settings"
  type = object({
    create               = bool
    name_prefix          = string
    description          = string
    engine_name          = string
    major_engine_version = string
    options = list(object({
      name = string
      settings = list(object({
        name  = string
        value = string
      }))
    }))
    tags = optional(list(string))
  })
}

variable "parameter_group" {
  description = "RDS instance parameter group settings"
  type = object({
    create               = bool
    name_prefix          = string
    description          = string
    family               = string
    major_engine_version = string
    parameter = list(object({
      name = string
      settings = list(object({
        name  = string
        value = string
      }))
    }))
    tags = optional(list(string))
  })
}

variable "subnet_group" {
  description = "RDS instance subnet group settings"
  type = object({
    create      = bool
    name_prefix = string
    description = string
    subnet_ids  = list(string)
    tags        = optional(list(string))
  })
}