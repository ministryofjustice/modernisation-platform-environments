variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster. Used for naming AWS resources like the NLB."
}

variable "cluster_base_domain" {
  type        = string
  description = "The base domain for the cluster (e.g., 'my-cluster.development.example.com'). Used for wildcard certificate generation and ListenerSet hostnames."
}

variable "envoy_proxy_replicas" {
  type        = number
  description = "The number of Envoy proxy pod replicas. Recommended: 2+ for HA, 3+ for production."
  default     = 2
}

variable "gateway_name" {
  type        = string
  description = "Name prefix for Gateway API resources (Gateway, GatewayClass, EnvoyProxy, ListenerSet). Should be DNS-compatible (lowercase alphanumeric and hyphens)."
}