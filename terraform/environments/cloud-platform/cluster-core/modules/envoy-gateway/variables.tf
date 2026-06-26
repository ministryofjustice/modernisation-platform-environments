variable cluster_name {
  type        = string
  description = "The name of the cluster"
}

variable cluster_base_domain {
  type        = string
  description = "The base domain for the cluster"
}

variable envoy_proxy_replicas {
  type        = number
  description = "The number of replicas for the Envoy proxy"
  default     = 2
}

variable "envoy_proxy_name" {
  type = string
}

variable "gateway_class_name" {
  type = string
}

variable "gateway_name" {
  type = string
}