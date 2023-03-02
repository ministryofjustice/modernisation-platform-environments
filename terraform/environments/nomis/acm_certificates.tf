module "acm_certificate" {
  for_each = merge(local.acm_certificates.common, local.acm_certificates[local.environment])

  source = "../../modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                    = each.key
  domain_name             = each.value.domain_name
  subject_alternate_names = each.value.subject_alternate_names
  validation              = each.value.validation
  tags                    = merge(local.tags, lookup(each.value, "tags", {}))
  cloudwatch_metric_alarms = {
    for key, value in merge(local.acm_certificates.common.cloudwatch_metric_alarms_acm, local.acm_certificates.production) :
    key => merge(value, {
      alarm_actions = [lookup(each.value, "sns_topic", aws_sns_topic.nomis_nonprod_alarms.arn)]
    })
  }
}
