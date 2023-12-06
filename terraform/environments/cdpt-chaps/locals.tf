locals {
  ecr_url  = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/cdpt-chaps-ecr-repo"
}
