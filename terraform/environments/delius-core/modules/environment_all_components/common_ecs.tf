module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=d3655d31c889272621066ac6b249ceadb7d23e3d"

  environment = var.env_name
  namespace   = var.app_name
  name        = "cluster"

  private_dns_namespace_enabled = true

  vpc_id = var.account_info.vpc_id

  tags = local.tags
}
