data "aws_availability_zones" "available" {}

################################################################################
# Cluster
################################################################################
#tfsec:ignore:AVD-AWS-0130
module "ecs_cluster" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.11.2"

  cluster_name = var.cluster_name

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    asg = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 90
        instance_warmup_period    = 300
      }
    }
  }

  tags = local.all_tags
}

#Service discovery namespace
resource "aws_service_discovery_private_dns_namespace" "namespace" {
  count       = var.service_discovery_namespace != "" ? 1 : 0
  name        = var.service_discovery_namespace
  vpc         = var.vpc_id
  description = "Private DNS namespace for ecs service discovery"
}
