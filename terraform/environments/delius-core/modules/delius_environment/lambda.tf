module "ecs_retirement_lambda" {
  count  = var.create_ecs_lambda ? 1 : 0
  source = "../components/ecs_retirement"

  env_name = var.env_name
  tags     = var.tags
}