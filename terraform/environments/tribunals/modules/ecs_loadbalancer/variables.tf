variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "vpc_shared_id" {
}

variable "application_data" {
}

variable "subnets_shared_public_ids" {
}

variable "aws_acm_certificate_external" {
}

variable "is_ftp_app" {
  description = "Determines if it is an ftp app or not"
}

variable "waf_arn" {
}

variable "target_group_attachment_port" {
  description = "The port of the target group"
}

variable "app_load_balancer" {
}
