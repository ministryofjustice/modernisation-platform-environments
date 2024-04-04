module "ecs" {
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=8096707cae17a51bb5bf1cc6a36ca2b6b9c633f0"
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
