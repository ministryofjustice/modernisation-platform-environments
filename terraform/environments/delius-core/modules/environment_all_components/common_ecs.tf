module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"

  environment = var.env_name
  namespace   = null
  name        = "cluster"

  tags = local.tags
}
