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
  type    = bool
  default = true
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "env_name" {
  description = "The name of the env where LB is being created"
  type        = string
}

variable "target_type" {
  type    = string
  default = "ip"
}

variable "deregistration_delay" {
  type    = string
  default = "30"
}

variable "tags" {
  type = any
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "subnet_ids" {
  description = "subnet ids"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
}

variable "port" {
  description = "port"
  type        = number
}

variable "secure_port" {
  description = "secure_port"
  type        = number
}


variable "protocol" {
  description = "protocol"
  type        = string
}

variable "mp_application_name" {
  description = "mp_application_name"
  type        = string
}

variable "zone_id" {
  description = "zone_id"
  type        = string
}

variable "app_name" {
  description = "app_name"
  type        = string
}

variable "certificate_arn" {
  description = "certificate_arn"
  type        = string
}