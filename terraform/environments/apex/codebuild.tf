module "apex-ecr-codebuild" {
  count  = local.environment == "development" ? 1 : 0
  source = "./modules/codebuild"

  app_name                                     = local.application_name
  account_id                                   = local.environment_management.account_ids[terraform.workspace]
  tags                                         = local.tags
  s3_lifecycle_expiration_days                 = 31
  s3_lifecycle_noncurr_version_expiration_days = 31
  core_shared_services_production_account_id   = local.environment_management.account_ids["core-shared-services-production"]
  local_ecr_url                                = "${local.environment_management.account_ids[terraform.workspace]}.dkr.ecr.eu-west-2.amazonaws.com/apex-local-ecr"
  application_test_url                         = local.application_test_url
}