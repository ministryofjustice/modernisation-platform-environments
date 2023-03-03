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

variable "validation" {
  type = map(object({
    account   = optional(string, "self")
    zone_name = string
  }))
  description = "Provider a list of zones to use for DNS validation where the key is the cert domain.  Set account to self, core-vpc or core-network-services"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "cloudwatch_metric_alarms" {
  description = "Map of cloudwatch metric alarms."
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
    tags                = optional(map(string))
  }))
  default = {}
}