module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.0"

  name        = local.application_name

  tags = local.tags
}
