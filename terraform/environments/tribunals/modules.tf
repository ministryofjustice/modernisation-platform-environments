module "ecs_loadbalancer" {
  source                            = "./modules/ecs_loadbalancer"
  app_name                          = "tribunals" #var.app_name
  tags_common                       = local.tags
}