module "acm_certificate" {
  for_each = var.acm_certificates

  source = "../../modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                                = each.key
  domain_name                         = each.value.domain_name
  subject_alternate_names             = each.value.subject_alternate_names
  route53_zones                       = local.route53_zones
  validation                          = each.value.validation
  external_validation_records_created = each.value.external_validation_records_created

  cloudwatch_metric_alarms = {
    for key, value in each.value.cloudwatch_metric_alarms : key => merge(value, {
      alarm_actions = [
        for item in value.alarm_actions : try(aws_sns_topic.this[item].arn, item)
      ]
    })
  }

  tags = merge(local.tags, lookup(each.value, "tags", {}))
}
