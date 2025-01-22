variable "alb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the load balancer"
  type        = string
}

variable "internal" {
  description = "Is the load balancer internal"
  default     = true
  type        = bool
}

variable "alb_subnets_ids" {
  description = "A list of subnet ids to attach to the load balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "The vpc id for the target group"
  type        = string
}

variable "enable_access_logs" {
  description = "Enable access logs for the load balancer"
  default     = false #s3 bucket doesn't exist yet #todo change to true after it exists
  type        = bool
}

variable "alb_ingress_with_source_security_group_id_rules" {
  description = "List of ingress rules for the ALB security group"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
    description              = string
  }))
  default = []
}

variable "count_alb_ingress_with_source_security_group_id_rules" {
  description = "The number of ingress rules for the ALB security group"
  type        = number
  default     = 0
}

variable "alb_ingress_with_cidr_blocks_rules" {
  description = "List of ingress rules for the ALB security group"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}


variable "target_groups" {
  description = "A map of target groups to create"
  type = map(object({
    name                              = string
    protocol                          = optional(string, "HTTP")
    port                              = optional(number, 8080)
    target_type                       = optional(string, "ip")
    deregistration_delay              = optional(number, 30)
    load_balancing_algorithm_type     = optional(string, "round_robin")
    load_balancing_cross_zone_enabled = optional(string, "use_load_balancer_configuration")
    protocol_version                  = optional(string, "HTTP1")
    create_attachment                 = optional(bool, false)
    health_check = optional(object({
      enabled             = bool
      interval            = number
      path                = string
      port                = string
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      protocol            = string
      matcher             = string
      }),
      {
        enabled             = true
        interval            = 110
        path                = "/actuator/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 100
        protocol            = "HTTP"
        matcher             = "200"
    })
  }))
  default = {}
}

variable "listeners" {
  description = "A map of listeners to create"
  type        = any
  default     = {}
}

variable "existing_target_groups" {
  description = "A map of existing target groups arns to use"
  type        = map(string)
  default     = {}
}

variable "alb_route53_record_zone_id" {
  description = "The zone id to create the route53 record in"
  type        = string
  default     = ""
}

variable "alb_route53_record_name" {
  description = "If you want to add a route53 record for the ALB set this and set the zone id"
  type        = string
  default     = ""
}

################################################################################
# WAF
################################################################################

variable "associate_web_acl" {
  description = "Indicates whether a Web Application Firewall (WAF) ACL should be associated with the load balancer"
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "Web Application Firewall (WAF) ARN of the resource to associate with the load balancer"
  type        = string
  default     = null
}

#todo uncomment once we have logging bucket
#variable "s3_access_logging_bucket" {
#  description = "The bucket to store the access logs"
#}
