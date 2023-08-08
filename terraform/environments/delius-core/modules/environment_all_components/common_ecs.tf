module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v2.0.1"

  environment = var.env_name
  name        = var.app_name

  tags = local.tags
}

# module "ecs" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"

#   environment = var.env_name
#   namespace   = var.app_name
#   name        = "cluster"

#   tags = local.tags
# }
