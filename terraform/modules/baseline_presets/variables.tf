variable "environment" {
  description = "Standard environmental data resources from the environment module"
}

variable "ip_addresses" {
  description = "ip address resources from the ip_address module"
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    cloudwatch_log_groups = optional(list(string))
    cloudwatch_metric_alarms = optional(map(object({
      application_alarms = optional(map(map(object({
        comparison_operator = string
        evaluation_periods  = number
        metric_name         = string
        namespace           = string
        period              = number
        statistic           = string
        threshold           = number
        actions_enabled     = optional(bool, false)
        alarm_description   = optional(string)
        datapoints_to_alarm = optional(number)
        treat_missing_data  = optional(string, "missing")
        dimensions          = optional(map(string), {})
      }))), {})
      alarm_actions     = optional(list(string))
      alarms_to_include = optional(list(string)) # null = all
      alarms_to_exclude = optional(list(string), [])
    })), {})
    enable_application_environment_wildcard_cert = optional(bool, false)
    enable_business_unit_kms_cmks                = optional(bool, false)
    enable_image_builder                         = optional(bool, false)
    enable_ec2_cloud_watch_agent                 = optional(bool, false)
    enable_ec2_self_provision                    = optional(bool, false)
    route53_resolver_rules                       = optional(map(list(string)), {})
    s3_iam_policies                              = optional(list(string))
    sns_topics_pagerduty_integrations            = optional(map(string), {})
  })
}
