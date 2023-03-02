module "acm_certificate" {
  for_each = var.acm_certificates

  source = "../../modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                     = each.key
  domain_name              = each.value.domain_name
  subject_alternate_names  = each.value.subject_alternate_names
  validation               = each.value.validation
  tags                     = merge(local.tags, lookup(each.value, "tags", {}))
  cloudwatch_metric_alarms = {}
}
