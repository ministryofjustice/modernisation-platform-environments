module "cloudwatch_yjaf" {
  source = "./modules/cloudwatch"


  project_name = local.project_name
  environment  = local.environment

}