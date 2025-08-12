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

variable "s3_buckets" {
  description = "map of s3 buckets to create where the map key is the bucket prefix.  See s3_bucket module for more variable details.  Use iam_policies to automatically create a iam policies for the bucket where the key is the name of the policy"
  type = map(object({
    acl                 = optional(string, "private")
    ownership_controls  = optional(string, "BucketOwnerPreferred")
    versioning_enabled  = optional(bool, true)
    replication_enabled = optional(bool, false)
    replication_region  = optional(string)
    bucket_policy       = optional(list(string), ["{}"])
    bucket_policy_v2 = optional(list(object({
      sid     = optional(string, null)
      effect  = string
      actions = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    custom_kms_key             = optional(string)
    custom_replication_kms_key = optional(string)
    lifecycle_rule             = any # see module baseline_presets.s3 for examples
    log_bucket                 = optional(string)
    log_prefix                 = optional(string, "")
    replication_role_arn       = optional(string, "")
    force_destroy              = optional(bool, false)
    sse_algorithm              = optional(string, "aws:kms")
    iam_policies = optional(map(list(object({
      sid     = optional(string, null)
      effect  = string
      actions = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    }))), {})
    tags = optional(map(string), {})
  }))
  default = {}
}
