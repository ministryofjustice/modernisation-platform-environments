variable "gateway_name" {
  description = "The name of the gateway"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "cluster_base_domain" {
  description = "The base domain of the cluster"
  type        = string
}