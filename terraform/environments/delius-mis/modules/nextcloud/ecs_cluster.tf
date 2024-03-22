module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"

  environment = var.env_name
  namespace   = "mis"
  name        = "cluster"

  tags = var.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-mis-${var.env_name}-"
  vpc_id      =  var.account_info.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
