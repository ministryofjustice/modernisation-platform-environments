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
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "${var.cluster_name}-ecs-ec2-keypair"
  create_private_key = true

  tags = local.all_tags
}

resource "aws_ssm_parameter" "ecs_private_key" {
  #checkov:skip=CKV_AWS_337 TODO
  name        = "/ec2/keypairs/ecs-private-key"
  description = "EC2 Private Key for esb-keypair"
  type        = "SecureString"
  value       = module.key_pair.private_key_pem
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

resource "aws_iam_policy" "ecs-fetch-secrets-policy" {
  name        = "ecs-fetch-secrets-policy"
  description = "Allows ecs services to fetch secrets from secrets manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:CancelRotateSecret"
        ],
        "Resource" : var.ecs_allowed_secret_arns
      }
    ]
  })
}

#tfsec:ignore:AVD-AWS-0130
module "autoscaling" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
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
    ecs-fetch-secrets-policy            = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
    AmazonS3FullAccess                  = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  #todo remove me once all 20 apps have iam role
    AmazonSESFullAccess                 = "arn:aws:iam::aws:policy/AmazonSESFullAccess" #todo remove me once all 20 apps have iam role
    ecs-eni-policy                      = aws_iam_policy.ecs-eni-policy.arn
    ecs-secrets-policy                  = aws_iam_policy.ecs-secrets-policy.arn #todo remove me once all 20 apps have iam role
    ecs-quicksight-policy               = aws_iam_policy.ecs-quicksight-policy.arn
  }
  security_groups = [module.autoscaling_sg.security_group_id]

  vpc_zone_identifier             = var.ecs_subnet_ids
  min_size                        = var.ec2_min_size
  max_size                        = var.ec2_max_size
  desired_capacity                = var.ec2_desired_capacity
  ignore_desired_capacity_changes = true #ecs is scaling itself
  desired_capacity_type           = "units"
  wait_for_capacity_timeout       = "60m"
  delete_timeout                  = "60m"

  # Launch template settings
  create_launch_template = true
  ebs_optimized          = false
  #launch_template_id     = aws_launch_template.this.id #todo try creating within the module instead
  launch_template_name = "${var.cluster_name}-ec2-launch-template"
  image_id             = var.ec2_ami_id != "" ? var.ec2_ami_id : local.ecs_optimized_ami.image_id #todo change to output of image builder
  instance_type        = var.ec2_instance_type
  key_name             = module.key_pair.key_pair_name
  #instance_market_options = {
  #  market_type = "spot" #todo change this later, spot temporarily to save money
  #}

  # Mixed instances
  use_mixed_instances_policy = false #no spot instances
  #mixed_instances_policy = { #uncomment for spot instances
  #  instances_distribution = {
  #    on_demand_base_capacity                  = 0
  #    on_demand_percentage_above_base_capacity = 10
  #    spot_allocation_strategy                 = "capacity-optimized"
  #  }

  #  override = var.spot_overrides
  #}

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

  #Networking this adds more secondary ips but doesn't solve the max eni issues
  #network_interfaces = [
  #  {
  #    ipv4_address_count = 10 # Assign 10 secondary IPs
  #  }
  #]


  # Scaling policies and tags
  schedules = local.schedules
  tags = merge(
    local.all_tags,
    { "OS" = "Linux" }
  )
  autoscaling_group_tags = merge( #ec2 tags
    local.all_tags,
    { "OS" = "Linux" }
  )

}

module "autoscaling_sg" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
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

  computed_ingress_with_source_security_group_id = concat(var.ec2_ingress_with_source_security_group_id_rules, local.common_datadog_rules)

  number_of_computed_ingress_with_source_security_group_id = length(var.ec2_ingress_with_source_security_group_id_rules)

  egress_rules = ["all-all"]

  tags = local.all_tags
}

resource "aws_iam_policy" "ecs-eni-policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  #checkov:skip=CKV_AWS_290: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_289: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_355: [TODO] Consider making the Resource reference more restrictive.

  name   = "${var.cluster_name}-ecs-eni"
  tags   = local.all_tags
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:ModifyNetworkInterfaceAttribute"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_policy" "ecs-secrets-policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  #checkov:skip=CKV_AWS_290: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_289: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_355: [TODO] Consider making the Resource reference more restrictive.
  #checkov:skip=CKV_AWS_288: [TODO] Ensure IAM policies does not allow data exfiltration

  name = "${var.cluster_name}-ecs-secrets"
  tags = local.all_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:CancelRotateSecret"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.secret_kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ecs-quicksight-policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  #checkov:skip=CKV_AWS_290: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_289: [TODO] Consider adding Constraints.
  #checkov:skip=CKV_AWS_355: [TODO] Consider making the Resource reference more restrictive.
  #checkov:skip=CKV_AWS_288: [TODO] Ensure IAM policies does not allow data exfiltration

  name = "${var.cluster_name}-quicksight-access"
  tags = local.all_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "quicksight:ListDashboards",
          "quicksight:GetDashboardEmbedUrl"
        ],
        "Resource" : [
          "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:dashboard/*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "quicksight:GetAuthCode",
          "quicksight:DescribeUser",
          "quicksight:RegisterUser",
          "quicksight:DeleteUser",
          "quicksight:ListUserGroups",
          "quicksight:ListUsers"
        ],
        "Resource" : [
          "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:user/default/*",
          "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:user/default/quicksight-admin-access/*"
        ]
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "quicksight:DescribeGroup",
          "quicksight:CreateGroup",
          "quicksight:ListGroups",
          "quicksight:ListGroupMemberships",
          "quicksight:CreateGroupMembership",
          "quicksight:DeleteGroupMembership",
          "quicksight:DeleteGroup"
        ],
        "Resource" : [
          "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:group/default/*"
        ]
      }
    ]
  })
}
