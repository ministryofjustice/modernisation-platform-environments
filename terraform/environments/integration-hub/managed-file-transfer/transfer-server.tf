resource "aws_transfer_server" "this" {
  certificate            = aws_acm_certificate.ftps.arn
  domain                 = "S3"
  endpoint_type          = "VPC"
  function               = module.lambda_custom_idp.lambda_function_arn
  identity_provider_type = "AWS_LAMBDA"
  logging_role           = module.iam_for_transfer.arn
  protocols              = ["SFTP", "FTPS"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${module.cloudwatch_transfer.cloudwatch_log_group_arn}:*"
  ]

  endpoint_details {
    vpc_id     = module.isolated_vpc.vpc_id
    subnet_ids = module.isolated_vpc.public_subnets
    address_allocation_ids = [
      for key, value in aws_eip.this : value.id
    ]
    security_group_ids = [
      aws_security_group.transfer.id
    ]
  }

  protocol_details {
    passive_ip = "AUTO"
  }

  tags = {
    "transfer:customHostname"      = local.is-production == false ? "sftp.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "sftp.managed-file-transfer.service.justice.gov.uk"
    "transfer:route53HostedZoneId" = "/hostedzone/${data.aws_route53_zone.service.zone_id}"
  }

  depends_on = [aws_acm_certificate.ftps]
}
