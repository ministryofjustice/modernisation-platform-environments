variable "wildcard_domain" {
  description = "Wildcard domain for the Gateway HTTPS listener"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name for the Gateway NLB"
  type        = string
}