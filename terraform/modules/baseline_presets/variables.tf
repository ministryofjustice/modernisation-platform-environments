variable "environment" {
  description = "Standard environmental data resources from the environment module"
}

variable "ip_addresses" {
  description = "ip address resources from the ip_address module"
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    backup_plan_daily_delete_after               = optional(number, 7)
    backup_plan_weekly_delete_after              = optional(number, 28)
    cloudwatch_log_groups                        = optional(list(string))
    cloudwatch_metric_alarms_default_actions     = optional(list(string))
    enable_application_environment_wildcard_cert = optional(bool, false)
    enable_backup_plan_daily_and_weekly          = optional(bool, false)
    enable_business_unit_kms_cmks                = optional(bool, false)
    enable_image_builder                         = optional(bool, false)
    enable_ec2_cloud_watch_agent                 = optional(bool, false)
    enable_ec2_self_provision                    = optional(bool, false)
    enable_ec2_put_parameter                     = optional(bool, false)
    enable_ec2_put_secret                        = optional(bool, false)
    enable_shared_s3                             = optional(bool, false)
    enable_oracle_secure_web                     = optional(bool, false)
    db_backup_s3                                 = optional(bool, false)
    route53_resolver_rules                       = optional(map(list(string)), {})
    iam_policies_filter                          = optional(list(string), [])
    iam_policies_ec2_default                     = optional(list(string), [])
    s3_iam_policies                              = optional(list(string))
    sns_topics = optional(object({
      pagerduty_integrations = optional(map(string), {})
      emails                 = optional(map(string), {})
      }), {
      pagerduty_integrations = {}
      emails                 = {}
    })
  })
}
