variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
  nullable    = false
}

variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  default     = "nomis"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "environment" {
  type        = string
  description = "Application environment - i.e. the terraform workspace"
}

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
    allocated_storage                   = number
    allow_major_version_upgrade         = optional(bool, false)
    apply_immediately                   = optional(bool, false)
    auto_minor_version_upgrade          = optional(bool, false)
    backup_retention_period             = optional(number, 1)
    backup_window                       = optional(string)
    character_set_name                  = optional(string)
    copy_tags_to_snapshot               = optional(bool, false)
    create                              = optional(bool, true)
    db_name                             = optional(string)
    db_subnet_group_name                = optional(string)
    enabled_cloudwatch_logs_exports     = optional(list(string))
    engine                              = string
    engine_version                      = optional(string)
    final_snapshot_identifier           = optional(bool, false)
    iam_database_authentication_enabled = optional(bool, false)
    instance_class                      = string
    iops                                = optional(number, 0)
    kms_key_id                          = optional(string)
    license_model                       = optional(string)
    maintenance_window                  = optional(string)
    max_allocated_storage               = optional(number)
    monitoring_interval                 = optional(number, 0)
    monitoring_role_arn                 = optional(string)
    multi_az                            = optional(bool, false)
    option_group_name                   = optional(string)
    parameter_group_name                = optional(string)
    password                            = string
    port                                = optional(string)
    publicly_accessible                 = optional(bool, false)
    replicate_source_db                 = optional(string)
    skip_final_snapshot                 = optional(bool, false)
    snapshot_identifier                 = optional(string)
    storage_encrypted                   = optional(bool, false)
    storage_type                        = optional(string, "gp2")
    username                            = string
    vpc_security_group_ids              = optional(list(string))
  })
}

variable "instance_automated_backups_replication" {
  type    = number
  default = 14
}

variable "option_group" {
  description = "RDS instance option group settings"
  type = object({
    create                   = bool
    name_prefix              = optional(string)
    option_group_description = optional(string)
    engine_name              = string
    major_engine_version     = string
    options = optional(list(object({
      option_name                    = string
      port                           = optional(number)
      version                        = optional(string)
      db_security_group_memberships  = optional(list(string))
      vpc_security_group_memberships = optional(list(string))
      option_settings = optional(list(object({
        name  = optional(string)
        value = optional(string)
      })))
    })))
    tags = optional(list(string))
  })
}

variable "parameter_group" {
  description = "RDS instance parameter group settings"
  type = object({
    create      = bool
    name_prefix = optional(string)
    description = optional(string)
    family      = string
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })))
    tags = optional(list(string))
  })
}

variable "subnet_group" {
  description = "RDS instance subnet group settings"
  type = object({
    create      = bool
    name_prefix = optional(string)
    description = optional(string)
    subnet_ids  = list(string)
    tags        = optional(list(string))
  })
}

variable "route53_record" {
  description = "Optionally create DNS entry"
  type        = bool
  default     = true
}

variable "iam_resource_names_prefix" {
  type        = string
  description = "Prefix IAM resources with this prefix, e.g. rds-instance-blabla"
  default     = "rds-instance"
}

variable "instance_profile_policies" {
  type        = list(string)
  description = "A list of managed IAM policy document ARNs to be attached to the database instance profile"
}

variable "ssm_parameters_prefix" {
  type        = string
  description = "Optionally prefix ssm parameters with this prefix.  Add a trailing /"
  default     = ""
}

variable "ssm_parameters" {
  description = "A map of SSM parameters to create.  If parameters are manually created, set to {} so IAM role still created"
  type = map(object({
    random = object({
      length  = number
      special = bool
    })
    description = string
    key_id      = optional(string)
  }))
  default = null
}
