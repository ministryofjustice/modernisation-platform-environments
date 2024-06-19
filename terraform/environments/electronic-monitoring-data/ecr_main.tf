module "ecr_lambda_repo" {
    source = "./modules/ecr"
    ecr_name = "lambdas/update_log_table"
}