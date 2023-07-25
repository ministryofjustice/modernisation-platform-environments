module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v2.0.1"

  environment = var.env_name
  name        = var.app_name

  tags = var.tags
}
