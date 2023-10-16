module "apex-ecr-codebuild" {
  count  = local.environment == "development" ? 1 : 0
  source = "./modules/codebuild"

  app_name                                     = local.application_name
  account_id                                   = local.environment_management.account_ids[terraform.workspace]
  tags                                         = local.tags
}