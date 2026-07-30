module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=89acd5cccf5238b2bdfb92746964864699cbf841" # v6.0.1

  name = "delius-core-${var.env_name}-cluster"

  tags = local.tags
}

resource "aws_security_group" "cluster" {
  #checkov:skip=CKV2_AWS_5: "SG passed to ecs service module"
  name_prefix = "ecs-cluster-${var.env_name}"
  vpc_id      = var.account_config.shared_vpc_id
  description = "ECS cluster SG"
  lifecycle {
    create_before_destroy = true
  }
}
