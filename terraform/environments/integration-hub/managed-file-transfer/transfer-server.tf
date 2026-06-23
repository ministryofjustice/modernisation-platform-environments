resource "aws_transfer_server" "this" {
  domain                 = "S3"
  endpoint_type          = "VPC"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = module.iam_for_transfer.arn
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${module.cloudwatch_transfer.cloudwatch_log_group_arn}:*"
  ]
  endpoint_details {
    vpc_id     = module.isolated_vpc.vpc_id
    subnet_ids = module.isolated_vpc.public_subnets
    address_allocation_ids = [
      aws_eip.this[0].id,
      aws_eip.this[1].id,
      aws_eip.this[2].id,
    ]
    security_group_ids = [
      aws_security_group.transfer.id
    ]
  }

  tags = {
    "transfer:customHostname"      = local.is-production == false ? "sftp.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "sftp.managed-file-transfer.service.justice.gov.uk"
    "transfer:route53HostedZoneId" = "/hostedzone/${data.aws_route53_zone.service.zone_id}"
  }
}

resource "aws_eip" "this" {
  count  = length(module.isolated_vpc.public_subnets)
  domain = "vpc"
}