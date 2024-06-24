variable "app_urls" {
  description = "URL for application"
  type        = list(string)
}

variable "certificate_arns" {
  description = "List of certificate ARNs to attach to loadbalancer listener"
  type        = list(string)
}