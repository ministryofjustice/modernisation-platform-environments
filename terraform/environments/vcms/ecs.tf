module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.0"

  name = "vcms-${local.environment}-cluster"

  tags = local.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${local.environment}"
  vpc_id      = local.account_config.shared_vpc_id
  description = "ECS cluster SG"
  lifecycle {
    create_before_destroy = true
  }
}

module "vcms_service" {
  source = "github.com/ministryofjustice/modernisation-platform-environments/terraform/environments/delius-core/modules/helpers/delius_microservice?ref=f191280"

  name = local.application_name

  env_name = local.environment

  container_vars_default = {}

  container_vars_env_specific = {}

  container_secrets_default = {}

  container_secrets_env_specific = {}

  desired_count = 1

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  cluster_security_group_id = aws_security_group.cluster.id

  sns_topic_arn = aws_sns_topic.vcms_alarms.arn

  account_config = local.account_config

  account_info = local.account_info

  bastion_sg_id = module.bastion_linux.bastion_security_group

  log_error_pattern = "placeholder"

  ecs_cluster_arn = module.ecs.ecs_cluster_arn

  container_image = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/vcms:${local.image_tag}"

  container_port_config = [
    {
      containerPort = 80
      protocol      = "tcp"
    }
  ]

  platform_vars = {
    environment_management = local.environment_management
  }

  tags = local.tags

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
}
