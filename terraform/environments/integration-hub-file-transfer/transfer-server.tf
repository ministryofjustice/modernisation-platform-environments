resource "aws_transfer_server" "this" {
  #certificate            = aws_acm_certificate.ftps.arn
  domain                 = "S3"
  endpoint_type          = "VPC"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = module.iam_role_transfer.arn
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${module.cloudwatch_transfer.cloudwatch_log_group_arn}:*"
  ]

  endpoint_details {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = data.aws_subnets.shared-public.ids
    address_allocation_ids = [
      for key, value in aws_eip.this : value.id
    ]
    security_group_ids = [
      module.security_group_transfer.id
    ]
  }

  protocol_details {
    passive_ip = "AUTO"
  }

  tags = {
    #"transfer:customHostname"      = local.is-production == false ? "sftp.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "sftp.managed-file-transfer.service.justice.gov.uk"
    #"transfer:route53HostedZoneId" = "/hostedzone/${data.aws_route53_zone.service.zone_id}"
  }

}
