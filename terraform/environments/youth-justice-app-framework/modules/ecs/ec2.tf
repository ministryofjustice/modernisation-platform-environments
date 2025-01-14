################################################################################
# Supporting Resources
################################################################################

#todo replace me with image builder output
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
data "aws_ssm_parameter" "ecs_optimized_ami" { #todo what should this be?
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

#create keypair for ec2 instances
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "${var.cluster_name}-ecs-ec2-keypair"
  create_private_key = true

  tags = local.all_tags
}

data "template_file" "userdata" {
  template = file("${path.module}/ec2-userdata.tftpl")
  vars = {
    nameserver   = var.nameserver
    env          = var.environment
    tags         = jsonencode(local.all_tags)
    project      = var.project_name
    cluster_name = var.cluster_name
  }
}

locals {
  ecs_optimized_ami = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.6.1"

  # Autoscaling group settings
  name                        = "${var.cluster_name}-ecs-instances"
  create_iam_instance_profile = true
  iam_role_name               = "${var.cluster_name}-ecs-instances-role"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonEC2RoleforSSM                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  }
  security_groups = [module.autoscaling_sg.security_group_id]

  vpc_zone_identifier   = var.ecs_subnet_ids
  min_size              = var.ec2_min_size
  max_size              = var.ec2_max_size
  desired_capacity      = var.ec2_desired_capacity
  desired_capacity_type = "units"

  # Launch template settings
  create_launch_template = true
  #launch_template_id     = aws_launch_template.this.id #todo try creating within the module instead
  launch_template_name = "${var.cluster_name}-ec2-launch-template"
  image_id             = local.ecs_optimized_ami.image_id #todo change to output of image builder
  instance_type        = var.ec2_instance_type
  key_name             = module.key_pair.key_pair_name
  #instance_market_options = {
  #  market_type = "spot" #todo change this later, spot temporarily to save money
  #}

  # Mixed instances
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 10
      spot_allocation_strategy                 = "capacity-optimized"
    }

    override = var.spot_overrides
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 60
        volume_type           = "gp2"
      }
    }
  ]
  enable_monitoring      = true
  update_default_version = true
  user_data              = base64encode(data.template_file.userdata.rendered)

  # Scaling policies and tags
  schedules = local.schedules
  tags      = local.all_tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "${var.cluster_name}-ecs-autoscaling-group"
  description = "Autoscaling group security group"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8125
      to_port                  = 8125
      protocol                 = "UDP"
      description              = "Datadog from ecs internal"
      source_security_group_id = aws_security_group.common_ecs_service_internal.id
    },
    {
      from_port                = 8125
      to_port                  = 8125
      protocol                 = "UDP"
      description              = "Datadog from ecs external"
      source_security_group_id = aws_security_group.common_ecs_service_external.id
    },
    {
      from_port                = 8126
      to_port                  = 8126
      protocol                 = "TCP"
      description              = "Datadog from ecs internal"
      source_security_group_id = aws_security_group.common_ecs_service_internal.id
    },
    {
      from_port                = 8126
      to_port                  = 8126
      protocol                 = "TCP"
      description              = "Datadog from ecs external"
      source_security_group_id = aws_security_group.common_ecs_service_external.id
    }
  ]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  computed_ingress_with_source_security_group_id = concat(var.ec2_ingress_with_source_security_group_id_rules, local.common_datadog_rule)

  number_of_computed_ingress_with_source_security_group_id = length(var.ec2_ingress_with_source_security_group_id_rules)

  egress_rules = ["all-all"]

  tags = local.all_tags
}
