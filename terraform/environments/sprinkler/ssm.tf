module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=0.0.1"
  providers = {
    aws.bucket-replication = aws
  }


  account_number   = local.environment_management.account_ids[terraform.workspace]
  application_name = local.application_name
  patch_schedule   = "cron(30 17 ? * MON *)"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}
