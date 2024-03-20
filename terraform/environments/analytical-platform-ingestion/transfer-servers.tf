
resource "aws_transfer_server" "this" {
  protocols                        = ["SFTP"]
  identity_provider_type           = "SERVICE_MANAGED"
  domain                           = "S3"
  post_authentication_login_banner = "Analytical Platform Ingestion - Development" # This doesn't work, at least on macOS SFTP client

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.public_subnets
    address_allocation_ids = [
      aws_eip.transfer_server[0].id,
      aws_eip.transfer_server[1].id,
      aws_eip.transfer_server[2].id,
    ]
    security_group_ids = [
      aws_security_group.transfer_server.id
    ]
  }

  security_policy_name = "TransferSecurityPolicy-2024-01"

  # Logging role is only required when using Managed workflows.
  # logging_role                = module.transfer_family_service_role.iam_role_arn

  structured_log_destinations = ["${aws_cloudwatch_log_group.transfer_structured_logs.arn}:*"]
}

resource "aws_transfer_tag" "this" {
  resource_arn = aws_transfer_server.this.arn
  key          = "aws:transfer:customHostname"
  value        = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk"
}
