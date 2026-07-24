resource "aws_transfer_server" "this" {
  #certificate            = aws_acm_certificate.ftps.arn
  domain                 = "S3"
  endpoint_type          = "VPC"
  function               = module.lambda_custom_idp.lambda_function_arn
  identity_provider_type = "AWS_LAMBDA"
  logging_role           = module.iam_role_transfer.arn
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${module.cloudwatch_transfer.cloudwatch_log_group_arn}:*"
  ]

  endpoint_details {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = local.transfer_subnet_ids
    address_allocation_ids = [
      for key, value in aws_eip.this : value.id
    ]
    security_group_ids = [
      aws_security_group.transfer.id
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-transfer-server"
      #"transfer:customHostname"      = local.is-production == false ? "sftp.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "sftp.managed-file-transfer.service.justice.gov.uk"
      #"transfer:route53HostedZoneId" = "/hostedzone/${data.aws_route53_zone.service.zone_id}"
    }
  )

}
