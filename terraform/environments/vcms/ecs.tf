module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v2.0.1"

  environment = local.environment
  name        = local.application_name

  tags = local.tags
}