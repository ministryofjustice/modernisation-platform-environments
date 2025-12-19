locals {
  logging_bucket_name             = "${local.application_name}-${local.environment}-logging"
  lb_log_prefix_edrmsapp_internal = "edrmsapps-internal-lb"


  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]

  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  lambda_folder_name = ["lambda_delivery", "ccms-edrms-docs-exception-layer", "cloudwatch_sns_layer"]

  lambda_source_hashes = [
    for f in fileset("./lambda/cloudwatch_alarm_slack_integration", "**") :
    sha256(file("${path.module}/lambda/cloudwatch_alarm_slack_integration/${f}"))
  ]

  cert_opts          = aws_acm_certificate.external.domain_validation_options
  cert_arn           = aws_acm_certificate.external.arn
  cert_zone_id       = data.aws_route53_zone.external.zone_id
}
