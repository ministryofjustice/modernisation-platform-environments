module "ecs_cluster" {
  # main = https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/COMMIT_SHA
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=main"

  cluster_name = "${local.component_name}-${local.env_label}-cluster"
  tags         = local.tags

  capacity_providers = {
    default = {
      instance_type         = local.application_data.accounts[local.environment].ec2_instance_type
      image_id              = local.application_data.accounts[local.environment].ami_image_id
      min_size              = local.application_data.accounts[local.environment].ec2_min_capacity
      max_size              = local.application_data.accounts[local.environment].ec2_max_capacity
      desired_capacity      = local.application_data.accounts[local.environment].ec2_desired_capacity
      root_volume_size      = local.application_data.accounts[local.environment].root_volume_size
      instance_profile_name = module.iam_ecs_ec2.instance_profile_name
      security_group_ids    = [module.sg_cluster_ec2.security_group_id]
      subnet_ids            = data.aws_subnets.shared-private.ids
      ebs_encrypted         = true
      kms_key_id            = data.aws_kms_key.ebs_shared.arn
    }
  }
}

# ecs-service module call will go here once built
