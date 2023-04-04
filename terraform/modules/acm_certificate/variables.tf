variable "name" {
  type        = string
  description = "Name of cert to use in tags.Name"
}

variable "domain_name" {
  type        = string
  description = "Domain name for which the certificate should be issued"
}

variable "subject_alternate_names" {
  type        = list(string)
  description = "Set of domains that should be SANs in the issued certificate"
  default     = []
}

variable "route53_zones" {
  description = "Provide a map of existing route53_zones that can be used for validation, e.g. from environment module route53_zones output.  Key is zone name and value must include zone_id and provider"
  default     = {}
}

variable "validation" {
  type = map(object({
    account   = optional(string, "self")
    zone_name = string
  }))
  description = "Provide a list of zones to use for DNS validation where the key is the cert domain.  Set account to self, core-vpc or core-network-services.  Only required if zones are not included in route53_zones variable"
  default     = {}
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "cloudwatch_metric_alarms" {
  description = "Map of cloudwatch metric alarms.  The alarm name is set to the cert name plus the map key."
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_actions       = list(string)
    actions_enabled     = optional(bool, false)
    alarm_description   = optional(string)
    datapoints_to_alarm = optional(number)
    treat_missing_data  = optional(string, "missing")
    dimensions          = optional(map(string), {})
  }))
  default = {}
}
