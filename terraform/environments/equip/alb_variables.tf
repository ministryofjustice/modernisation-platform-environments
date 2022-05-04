variable "name" {
  description = "The resource name and Name tag of the load balancer."
  type        = string
  default     = "citrix"
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are application or network."
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Boolean determining if the load balancer is internal or externally facing."
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "The security groups to attach to the load balancer"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "A list of subnets to associate with the load balancer. e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f']"
  type        = list(string)
  default     = null
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 60
}

variable "enable_cross_zone_load_balancing" {
  description = "Indicates whether cross zone load balancing should be enabled in application load balancers."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers."
  type        = bool
  default     = true
}


variable "access_logs" {
  description = "Map containing access logging configuration for load balancer."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = { terraform_managed = "true" }
}

variable "lb_tgt_port" {
  description = "The port that the downstream server exposes over HTTP/Https"
  type        = number
  default     = 80
}

variable "lb_tgt_health_check_path" {
  description = "The path to bind for health checks"
  type        = string
  default     = "/"
}

variable "lb_tgt_matcher" {
  description = "The response codes expected for health checks"
  default     = "200-399"
  type        = string
}

variable "lb_tgt_protocol_version" {
  description = "Send request to target using HTTP/1.1, HTTP/2, gRPC"
  type        = string
  default     = "HTTP1"
}

variable "lb_tgt_protocol" {
  description = "Routing Traffic to the Targets"
  type        = string
  default     = "HTTP"
}

variable "lb_tgt_target_type" {
  description = "Type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "instance"
}
