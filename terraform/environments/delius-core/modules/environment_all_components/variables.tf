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
    mp_environment   = string,
    id               = string
  })
}

#variable "ldap_migration_bucket_arn" {
#  type = string
#}

variable "network_config" {
  type = object({
    shared_vpc_cidr                = string
    shared_vpc_id                  = string
    private_subnet_ids             = list(string)
    route53_inner_zone_info        = any
    route53_network_services_zone  = any
    route53_external_zone          = any
    migration_environment_vpc_cidr = optional(string)
    general_shared_kms_key_arn     = optional(string)
  })
  default = {
    shared_vpc_cidr                = "default_shared_vpc_cidr"
    shared_vpc_id                  = "default_shared_vpc_id"
    private_subnet_ids             = ["default_private_subnet_a_id"]
    route53_inner_zone_info        = {}
    route53_network_services_zone  = {}
    route53_external_zone          = {}
    migration_environment_vpc_cidr = "default_migration_environment_vpc_cidr"
    general_shared_kms_key_arn     = "default_general_shared_kms_key_arn"
  }
}

variable "ldap_config" {
  type = object({
    name                        = string
    migration_source_account_id = string
    migration_lambda_role       = string
    efs_throughput_mode         = string
    efs_provisioned_throughput  = string
    efs_backup_schedule         = string
    efs_backup_retention_period = string

  })
  default = {
    name                        = "default_name"
    migration_source_account_id = "default_migration_source_account_id"
    migration_lambda_role       = "default_migration_lambda_role"
    efs_throughput_mode         = "default_efs_throughput_mode"
    efs_provisioned_throughput  = "default_efs_provisioned_throughput"
    efs_backup_schedule         = "default_efs_backup_schedule"
    efs_backup_retention_period = "default_efs_backup_retention_period"
  }
}

variable "weblogic_config" {
  type = object({
    name                          = string
    frontend_service_name         = string
    frontend_fully_qualified_name = string
    frontend_image_tag            = string
    frontend_container_port       = number
    frontend_url_suffix           = string
    db_name                       = string
  })
  default = {
    name                          = "default_name"
    frontend_service_name         = "default_frontend_service_name"
    frontend_fully_qualified_name = "default_frontend_fully_qualified_name"
    frontend_image_tag            = "default_frontend_image_tag"
    frontend_container_port       = 8080
    frontend_url_suffix           = "default_frontend_url_suffix"
    db_name                       = "default_db_name"
  }

}

variable "db_config" {
  type = object({
    name = string
  })
  default = {
    name = "default_name"
  }
}

variable "tags" {
  type = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}
