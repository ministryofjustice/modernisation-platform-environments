resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternate_names
  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# use core-network-services provider to validate top-level domain
resource "aws_route53_record" "validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.validation_records : key => value if value.zone.provider == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type

  # NOTE: value.zone is null indicates the validation zone could not be found
  # Ensure route53_zones variable contains the given validation zone or
  # explicitly provide the zone details in the validation variable.
  zone_id = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

# use core-vpc provider to validate business-unit domain
resource "aws_route53_record" "validation_core_vpc" {
  provider = aws.core-vpc
  for_each = {
    for key, value in local.validation_records : key => value if value.zone.provider == "core-vpc"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

# assume any other domains are defined in the current workspace
resource "aws_route53_record" "validation_self" {
  for_each = {
    for key, value in local.validation_records : key => value if value.zone.provider == "self"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

resource "aws_acm_certificate_validation" "this" {
  count           = (length(local.validation_records_external) == 0 || var.external_validation_records_created) ? 1 : 0
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = [
    for record in merge(
      aws_route53_record.validation_core_network_services,
      aws_route53_record.validation_core_vpc,
      aws_route53_record.validation_self
    ) : record.fqdn
  ]
  depends_on = [
    aws_route53_record.validation_core_network_services,
    aws_route53_record.validation_core_vpc,
    aws_route53_record.validation_self
  ]
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.cloudwatch_metric_alarms

  alarm_name          = "${var.name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = each.value.alarm_actions
  alarm_description   = each.value.alarm_description
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data
  dimensions = merge(each.value.dimensions, {
    "CertificateArn" = aws_acm_certificate.this.arn
  })
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
