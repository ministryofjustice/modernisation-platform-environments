variable "name" {
  type        = string
  description = "Name of the listener for tag:Name"
}

variable "business_unit" {
  type        = string
  description = "Modernisation platform business unit, e.g. hmpps"
}

variable "environment" {
  type        = string
  description = "Modernisation platform environment, e.g. development"
}

variable "load_balancer" {
  description = "Provide aws_lb resource or data resource"
  default     = null
}

variable "load_balancer_arn" {
  type        = string
  description = "As alternative to using load_balancer variable, use ARN of the load balancer"
  default     = null
}

variable "existing_target_groups" {
  description = "Map of existing aws_lb_target_groups, if looking up target group by name (map key)"
  default     = {}
}

variable "port" {
  type        = number
  description = "Port on which the load balancer is listening"
}

variable "protocol" {
  type        = string
  description = "Protocol for connections from clients to the load balancer"
}

variable "ssl_policy" {
  type        = string
  description = "Name of the SSL Policy for the listener. Required if protocol is HTTPS"
  default     = null
}

variable "certificate_arn_lookup" {
  type        = map(string)
  description = "Map of certficate name to ARN.  Use this if certificate not yet created to avoid for_each determined error"
  default     = {}
}

variable "certificate_names_or_arns" {
  type        = list(string)
  description = "List of SSL certificate names or ARNs to associate with the listener.  If names, ensure certificate_lookup variable is used.  The first certificate provided is the default"
  default     = []
}

variable "default_action" {
  description = "Configuration block for default actions"
  type = object({
    type              = string
    target_group_name = optional(string)
    target_group_arn  = optional(string) # use this if target group defined elsewhere
    fixed_response = optional(object({
      content_type = string
      message_body = optional(string)
      status_code  = optional(string)
    }))
    forward = optional(object({
      target_group = list(object({
        name       = optional(string)
        arn        = optional(string) # use this if target group defined elsewhere
        stickiness = optional(number)
      }))
      stickiness = optional(object({
        duration = optional(number)
        enabled  = bool
      }))
    }))
    redirect = optional(object({
      status_code = string
      port        = optional(number)
      protocol    = optional(string)
    }))
  })
}

variable "rules" {
  description = "Map of additional aws_lb_listener_rules where key is the tag:Name"
  type = map(object({
    priority = optional(number)
    actions = list(object({
      type              = string
      target_group_name = optional(string, null)
      target_group_arn  = optional(string, null) # use this if target group defined elsewhere
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = optional(string)
      }))
      forward = optional(object({
        target_group = list(object({
          name       = optional(string)
          arn        = optional(string) # use this if target group defined elsewhere
          stickiness = optional(number)
        }))
        stickiness = optional(object({
          duration = optional(number)
          enabled  = bool
        }))
      }))
      redirect = optional(object({
        status_code = string
        port        = optional(number)
        protocol    = optional(string)
      }))
    }))
    conditions = list(object({
      host_header = optional(object({
        values = list(string)
      }))
      path_pattern = optional(object({
        values = list(string)
      }))
    }))
  }))
}

variable "route53_records" {
  description = "Map of route53 records to associate with load balancer, where key is the DNS name"
  type = map(object({
    account                = string # account to create the record in.  set to core-vpc or self
    zone_id                = string # id of zone to create the record in
    evaluate_target_health = bool
  }))
  default = {}
}

variable "replace" {
  description = "A bit of a bodge to make definition of rules and default_action reusable.  Does a search/replace on the target_group_name field in rules/default_action contains with target_group_name_match/target_group_name_replace.  Likewise with the condition host header.  Useful when you have multiple environments with same config"
  type = object({
    target_group_name_match       = optional(string, "$(name)")
    target_group_name_replace     = optional(string, "")
    condition_host_header_match   = optional(string, "$(name)")
    condition_host_header_replace = optional(string, "")
    route53_record_name_match     = optional(string, "$(name)")
    route53_record_name_replace   = optional(string, "")
  })
  default = {}
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "cloudwatch_metric_alarms" {
  description = "Map of cloudwatch metric alarms.  The alarm name is set to the target group name plus the map key."
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

variable "alarm_target_group_names" {
  description = "List of target groups names that should have load-balancer (lb) alarms for them"
  type        = list(string)
  default     = []
}
