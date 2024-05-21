module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=75bcf32974b1754ee8e34916f2a8a019ec20a6ad"
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = local.application_name
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}
