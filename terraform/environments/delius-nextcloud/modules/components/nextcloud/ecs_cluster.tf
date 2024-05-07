module "ecs" {
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v4.2.1"
  name                      = "nextcloud-cluster"
  enable_container_insights = "enabled"
  tags                      = var.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-mis-${var.env_name}-"
  vpc_id      = var.account_info.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
