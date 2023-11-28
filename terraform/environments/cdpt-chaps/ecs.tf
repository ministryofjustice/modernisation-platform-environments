module "ecs-cluster" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v3.0.0"

  environment                = local.environment
  name                       = local.application_name
  namespace                  = local.application_name

  tags = local.tags
}
