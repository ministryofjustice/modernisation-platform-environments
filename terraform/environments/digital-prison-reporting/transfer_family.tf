resource "aws_transfer_server" "poc_transfer_spike" {
  protocols = ["SFTP"]

  identity_provider_type = "SERVICE_MANAGED"
  domain = "S3"
  endpoint_type = "VPC" // Only accessible via our VPC
  security_policy_name = "TransferSecurityPolicy-2025-03"

  // logging_role = (Optional) Amazon Resource Name (ARN) of an IAM role that allows the service to write your SFTP users’ activity to your Amazon CloudWatch logs for monitoring and auditing purposes.

  endpoint_details {
    subnet_ids             = local.dpr_subnets
    vpc_id                 = local.dpr_vpc
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-transfer-family-server-spike-${local.env}"
      Resource_Type = "Transfer Family Server"
      Jira          = "DPR2-1499"
    }
  )

}