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

variable "load_balancer_arn" {
  type        = string
  description = "ARN of the load balancer"
}

variable "target_groups" {
  description = "Map of target groups, where key is the name_prefix"
  type = map(object({
    port                 = optional(number)
    protocol             = optional(string)
    target_type          = string
    deregistration_delay = optional(number)
    health_check = optional(object({
      enabled             = optional(bool)
      interval            = optional(number)
      healthy_threshold   = optional(number)
      matcher             = optional(string)
      path                = optional(string)
      port                = optional(number)
      timeout             = optional(number)
      unhealthy_threshold = optional(number)
    }))
    stickiness = optional(object({
      enabled         = optional(bool)
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    attachments = optional(list(object({
      target_id         = string
      port              = optional(number)
      availability_zone = optional(string)
    })), [])
  }))
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

variable "certificate_arns" {
  type        = list(string)
  description = "List of SSL certificage ARNs to associate with the listener"
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

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

