variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "ingress_class_name" {
  description = "Name of the Ingress class"
  type        = string
  default     = "alb"
}

variable "scheme" {
  description = "ALB scheme - internet-facing or internal (configured in IngressClassParams)"
  type        = string
  default     = "internet-facing"
  validation {
    condition     = contains(["internet-facing", "internal"], var.scheme)
    error_message = "Scheme must be either 'internet-facing' or 'internal'."
  }
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener"
  type        = string
}

variable "envoy_service_name" {
  description = "Name of the Envoy Gateway service"
  type        = string
}

variable "envoy_namespace" {
  description = "Kubernetes namespace where Envoy service is deployed"
  type        = string
}

variable "envoy_service_port" {
  description = "Port number of the Envoy service"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/"
}

variable "redirect_http_to_https" {
  description = "Whether to redirect HTTP traffic to HTTPS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the ALB (configured in IngressClassParams)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Kubernetes labels to apply to Ingress resource"
  type        = map(string)
  default     = {}
}
