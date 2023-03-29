variable "environment" {
  description = "Standard environmental data resources from the environment module"
}

variable "ip_addresses" {
  description = "ip address resources from the ip_address module"
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    cloudwatch_log_groups                        = optional(list(string))
    enable_application_environment_wildcard_cert = optional(bool, false)
    enable_business_unit_kms_cmks                = optional(bool, false)
    enable_image_builder                         = optional(bool, false)
    enable_ec2_cloud_watch_agent                 = optional(bool, false)
    enable_ec2_self_provision                    = optional(bool, false)
    route53_resolver_rules                       = optional(map(list(string)), {})
    s3_iam_policies                              = optional(list(string))
  })
}
