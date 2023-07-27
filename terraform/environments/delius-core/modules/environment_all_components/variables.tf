variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = object({
    business_unit    = string,
    region           = string,
    vpc_id           = string,
    application_name = string,
    mp_environment   = string
  })
}

#variable "ldap_migration_bucket_arn" {
#  type = string
#}

variable "network_config" {
  type = object({
    shared_vpc_cidr                = string
    private_subnet_ids             = list(string)
    route53_inner_zone_info        = any
    migration_environment_vpc_cidr = optional(string)
    some_other_attribute           = optional(string)
  })
  default = {
    shared_vpc_cidr                = "default_shared_vpc_cidr"
    private_subnet_ids             = ["default_private_subnet_a_id"]
    route53_inner_zone_info        = {}
    migration_environment_vpc_cidr = "default_migration_environment_vpc_cidr"
    some_other_attribute           = "default_some_other_attribute"
  }
}

variable "ldap_config" {
  type = object({
    name                        = string
    migration_source_account_id = string
    migration_lambda_role       = string
    efs_backup_schedule         = string
    efs_backup_retention_period = string

  })
  default = {
    name                        = "default_name"
    migration_source_account_id = "default_migration_source_account_id"
    migration_lambda_role       = "default_migration_lambda_role"
    efs_backup_schedule         = "default_efs_backup_schedule"
    efs_backup_retention_period = "default_efs_backup_retention_period"
  }
}

variable "db_config" {
  type = object({
    name                 = string
    some_other_attribute = optional(string)
  })
  default = {
    name                 = "default_name"
    some_other_attribute = "default_some_other_attribute"
  }
}

variable "tags" {
  type = any
}