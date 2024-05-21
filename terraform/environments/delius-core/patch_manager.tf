module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=73680b4951b9d6c97773dbe9cae146cd1512ffcc"
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
