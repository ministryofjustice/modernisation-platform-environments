variable "name" {
  type        = string
  description = "Name of the ALB. Will be used for the AWS resource name and tags."
}

variable "subnets" {
  type        = list(string)
  description = "Public subnets for the ALB."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB target group."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the ALB."
}

variable "tags" {
  type        = map(string)
  description = "Common tags for the ALB resources."
}

variable "access_logs_bucket" {
  type        = string
  description = "S3 bucket name used for ALB access logs."
}

variable "listener_protocol" {
  type        = string
  description = "Protocol used by the ALB listener."
  default     = "HTTPS"
}

variable "listener_port" {
  type        = number
  description = "Port used by the ALB listener."
  default     = 443
}

variable "alb_ssl_policy" {
  type        = string
  description = "SSL policy for the ALB listener."
  default     = "ELBSecurityPolicy-2016-08"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for the ALB listener."
}

variable "target_group_name" {
  type        = string
  description = "Name of the ALB target group."
}

variable "target_group_port" {
  type        = number
  description = "Port used by the ALB target group."
  default     = 80
}

variable "target_group_protocol" {
  type        = string
  description = "Protocol used by the ALB target group."
  default     = "HTTP"
}

variable "healthcheck_path" {
  type        = string
  description = "Path used by the target group health check."
}

variable "healthcheck_protocol" {
  type        = string
  description = "Protocol used by the target group health check."
  default     = "HTTP"
}

variable "healthcheck_interval" {
  type        = number
  description = "Health check interval in seconds."
  default     = 15
}

variable "healthcheck_timeout" {
  type        = number
  description = "Health check timeout in seconds."
  default     = 5
}

variable "healthcheck_healthy_threshold" {
  type        = number
  description = "Healthy threshold for the target group health check."
  default     = 2
}

variable "healthcheck_unhealthy_threshold" {
  type        = number
  description = "Unhealthy threshold for the target group health check."
  default     = 3
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion protection is enabled for the ALB."
  default     = false
}

variable "idle_timeout" {
  type        = number
  description = "Idle timeout for ALB connections, in seconds."
  default     = 60
}
