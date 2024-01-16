variable "internal" {
  description = "whether the LB is internal or not. Defaults to `true`"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "The type of load balancer to create."
  type        = string
  default     = "network"
}

variable "drop_invalid_header_fields" {
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
}

variable "env_name" {
  description = "The name of the env where LB is being created"
  type        = string
}

variable "target_type" {
  type        = string
  default     = "ip"
}

variable "deregistration_delay" {
  type        = string
  default     = "30"
}

variable "tags" {
  type = any
}

variable account_config {
  type = any
}

variable account_info {
  type = any
}

