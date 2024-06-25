module "ecr_lambda_repo" {
  source   = "./modules/ecr"
  ecr_name = "lambdas/update_log_table"
}

module "ecr_lambdas_repo" {
  source   = "./modules/ecr"
  ecr_name = "lambda-functions-repo"
}