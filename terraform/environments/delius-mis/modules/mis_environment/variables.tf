variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = any
}

variable "account_config" {
  type = any
}

variable "environment_config" {
  type = any
}

variable "bastion_config" {
  type = any
}

variable "bcs_config" {
  type = any
}

variable "bps_config" {
  type = any
}

variable "bws_config" {
  type = any
}

variable "dis_config" {
  type = any
}

variable "tags" {
  type = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "dsd_db_config" {
  type = any
}

variable "boe_db_config" {
  type = any
}

variable "mis_db_config" {
  type = any
}

variable "fsx_config" {
  type = any
}

variable "auto_config" {
  type    = any
  default = null #optional
}

variable "dfi_config" {
  type    = any
  default = null #optional
}

variable "dfi_report_bucket_config" {
  type    = any
  default = null #optional
}

variable "deploy_oracle_stats" {
  description = "for deploying Oracle stats bucket"
  default     = true
  type        = bool
}

variable "environments_in_account" {
  type    = list(string)
  default = []
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = null
}

variable "domain_join_ports" {
  description = "Ports required for domain join"
  type        = any
}

variable "lb_config" {
  description = "params for Classic Load Balancer"
  type        = any
  default     = null
}

variable "internal_security_group_cidrs" {
  description = "List of CIDR blocks allowed to access internal services"
  type        = list(string)
  default     = []
}
