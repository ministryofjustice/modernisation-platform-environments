module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching?ref=58f4d7e159d1670010ee97b83040e37f3c559c87" # v3.1.0
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
