module "ecs_loadbalancer" {
  source                            = "./modules/ecs_loadbalancer"
  app_name                          = var.app_name
  tags_common                       = local.tags
}