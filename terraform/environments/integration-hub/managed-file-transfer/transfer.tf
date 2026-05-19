resource "aws_transfer_server" "this" {
  domain                 = "S3"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = module.iam_for_transfer.arn
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
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
}

resource "aws_eip" "this" {
  count = length(module.isolated_vpc.public_subnets)
  domain = "vpc"
}