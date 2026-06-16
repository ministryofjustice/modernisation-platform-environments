locals {
  cluster_base_domain = var.cluster_base_domain != null ? var.cluster_base_domain : var.base_domain_map[var.cluster_environment]

  certificate_arn = var.certificate_arn != null ? var.certificate_arn : try(aws_acm_certificate_validation.cluster_wildcard[0].certificate_arn, null)
}