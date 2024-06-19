module "ecr_lambda_repo" {
    source = "./modules/ecr"
    ecr_name = "lambdas/lambda-functions-repo"
}