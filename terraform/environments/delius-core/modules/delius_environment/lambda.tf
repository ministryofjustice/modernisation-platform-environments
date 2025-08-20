module "ecs_retirement_lambda" {
    source = "../components/ecs_retirement"

    env_name = var.env_name
    tags = var.tags
}