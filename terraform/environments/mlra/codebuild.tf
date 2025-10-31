
module "mlra-selenium" {
  #checkov:skip=CKV_AWS_316:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  #checkov:skip=CKV_AWS_314:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  count  = local.environment == "development" ? 1 : 0
  source = "./modules/codebuild"

  app_name                                     = local.application_name
  environment                                  = local.environment
  tags                                         = local.tags
  s3_lifecycle_expiration_days                 = 31
  s3_lifecycle_noncurr_version_expiration_days = 31
  application_test_url                         = local.application_test_url
  account_id                                   = local.environment_management.account_ids[terraform.workspace]
  local_ecr_url                                = "${local.environment_management.account_ids[terraform.workspace]}.dkr.ecr.eu-west-2.amazonaws.com/mlra-local-ecr"
  core_shared_services_production_account_id   = local.environment_management.account_ids["core-shared-services-production"]
}
