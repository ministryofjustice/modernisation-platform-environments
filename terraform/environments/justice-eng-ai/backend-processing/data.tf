# VPC ID exported by the parent justice-eng-ai Terraform root.
data "terraform_remote_state" "justice_eng_ai" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket               = "modernisation-platform-terraform-state"
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    workspace_key_prefix = "environments/members/justice-eng-ai"
  }
}

#cluster arn
data "aws_ecs_cluster" "prototype_deployment" {
  count        = local.prototype_deployment_enabled ? 1 : 0
  cluster_name = "${local.application_name}-prototypes-app"
}

#vpc id
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}"]
  }
}

#private subnet ids
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*-private-eu-west-2*"]
  }
}

#ECS security group
data "aws_security_group" "prototype_deployment" {
  count = local.prototype_deployment_enabled ? 1 : 0
  name  = "${local.application_name}-prototypes-app"
}

#Load Balancer
data "aws_lb" "prototype_deployment" {
  count = local.prototype_deployment_enabled ? 1 : 0
  name  = "${local.application_name}-prototypes-alb"
}

#listener rule 
data "aws_lb_listener" "prototype_deployment" {
  count             = local.prototype_deployment_enabled ? 1 : 0
  load_balancer_arn = data.aws_lb.prototype_deployment[0].arn
  port              = 443
}

#Route53 zone 
data "aws_route53_zone" "prototype_deployment" {
  count        = local.prototype_deployment_enabled ? 1 : 0
  name         = local.is-production ? "ai-builder.modernisation-platform.service.justice.gov.uk" : "ai-builder-dev.modernisation-platform.service.justice.gov.uk"
  private_zone = false
}