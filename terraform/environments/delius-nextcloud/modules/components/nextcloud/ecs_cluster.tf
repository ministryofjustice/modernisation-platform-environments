module "ecs" {
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v4.3.0"
  name                      = "nextcloud-${var.env_name}-cluster"
  enable_container_insights = "enabled"
  tags                      = var.tags
}

resource "aws_security_group" "cluster" {
  name   = "ecs-cluster-nextcloud-${var.env_name}"
  vpc_id = var.account_info.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
