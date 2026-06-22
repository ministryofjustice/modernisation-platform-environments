variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS-01 ACME challenges"
  type        = string
}
