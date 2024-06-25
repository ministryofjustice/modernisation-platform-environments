variable "application_data" {}

variable "app_name" {}

variable "app_urls" {
  description = "URL for application"
  type        = list(string)
}

variable "certificate_arns" {
  description = "List of certificate ARNs to attach to loadbalancer listener"
  type        = list(string)
}

variable "vpc_shared_id" {}

variable "subnets_shared_public_ids" {}