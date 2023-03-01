variable "account_number" {
  type        = string
  description = "Account number of current environment"
}
variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "environment" {}

variable "application_name" {
  type        = string
  description = "Name of application"
}
variable "public_subnets" {
  type        = list(string)
  description = "Public subnets"
}
variable "private_subnets" {
  type        = list(string)
  description = "Private subnets"
}
variable "vpc_all" {
  type        = string
  description = "The full name of the VPC (including environment) used to create resources"
}
variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
}
variable "region" {
  type        = string
  description = "AWS Region where resources are to be created"
}
variable "idle_timeout" {
  type        = string
  description = "The time in seconds that the connection is allowed to be idle."
}
variable "force_destroy_bucket" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
variable "security_group_ingress_from_port" {
  type        = string
  description = "The from port for the lb ingress rules"
}
variable "security_group_ingress_to_port" {
  type        = string
  description = "The to port for the lb ingress rules"
}
variable "security_group_ingress_protocol" {
  type        = string
  description = "The protocol for the lb ingress rules"
}
variable "moj_vpn_cidr_block" {
  type        = string
  description = "The cidr block for the lb ingress rules from MoJ VPN"
}
variable "listener_port" {
  type        = string
  description = "The port number for the ALB Listener"
}
variable "listener_protocol" {
  type        = string
  description = "The protocol for the ALB Listener"
}
variable "target_group_port" {
  type        = string
  description = "The port number for the ALB Target Group"
}
variable "target_group_protocol" {
  type        = string
  description = "The protocol for the ALB Target Group"
}
variable "vpc_id" {
  type        = string
  description = "The id for the VPC"
}
variable "target_group_deregistration_delay" {
  type        = string
  description = "The time in seconds for the deregistration delay"
}
variable "healthcheck_interval" {
  type        = string
  description = "The time in seconds for the health check interval"
}
variable "healthcheck_path" {
  type        = string
  description = "The path value for the health check"
}
variable "healthcheck_protocol" {
  type        = string
  description = "The protocol for the health check"
}
variable "healthcheck_timeout" {
  type        = string
  description = "The tiomeout in seconds for the health check"
}
variable "healthcheck_healthy_threshold" {
  type        = string
  description = "The healthy threshold in seconds for the health check"
}
variable "healthcheck_unhealthy_threshold" {
  type        = string
  description = "The unhealthy threshold in seconds for the health check"
}
variable "stickiness_enabled" {
  type        = bool
  description = "The enabled setting for the stickiness"
}
variable "stickiness_type" {
  type        = string
  description = "The type setting for the stickiness"
}
variable "stickiness_cookie_duration" {
  type        = string
  description = "The cookie duration in seconds for the stickiness"
}
variable "internal_lb" {
  type        = bool
  description = "Internal Schema LB or not. Use true for internal"
}
variable "existing_bucket_name" {
  type        = string
  default     = ""
  description = "The name of the existing bucket name. If no bucket is provided one will be created for them."
}
