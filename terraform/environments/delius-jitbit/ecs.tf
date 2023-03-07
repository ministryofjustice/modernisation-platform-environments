#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=a851639"

  subnet_set_name         = local.subnet_set_name
  app_name                = local.application_name
  container_instance_type = local.application_data.accounts[local.environment].container_instance_type
  ami_image_id            = data.aws_ami.ecs_ami.id

  instance_type = local.application_data.accounts[local.environment].instance_type
  user_data = base64encode(templatefile("templates/user-data.txt", {
    CLUSTER_NAME = local.application_name
  }))
  key_name               = local.application_data.accounts[local.environment].key_name
  task_definition        = local.task_definition
  ec2_desired_capacity   = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size           = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size           = local.application_data.accounts[local.environment].ec2_min_size
  container_cpu          = local.application_data.accounts[local.environment].container_cpu
  container_memory       = local.application_data.accounts[local.environment].container_memory
  task_definition_volume = local.application_data.accounts[local.environment].task_definition_volume
  network_mode           = local.application_data.accounts[local.environment].network_mode
  server_port            = local.application_data.accounts[local.environment].server_port
  app_count              = local.application_data.accounts[local.environment].app_count
  tags_common            = local.tags
  lb_tg_name             = aws_lb_target_group.target_group.name
  ec2_ingress_rules      = local.ec2_ingress_rules
  ec2_egress_rules       = local.ec2_egress_rules

  # removed a depends on here on the loadbalancer listener - if plan failing, try re-add
  # adding a module dependson forced terraform to plan the recreation of resources in the module
  # e.g. the ec2 cluster security group

  depends_on = [aws_lb_listener.listener, aws_lb_target_group.target_group]
  vpc_id     = data.aws_vpc.shared.id
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ecs-new" {
  source = "github.com/ministryofjustice/terraform-ecs//cluster?ref=3c9a5a0762c7b2dbff6608e606a2784c8a4ef9c4"

  environment = local.environment
  name        = format("%s-new", local.application_name)

  tags = local.tags
}

#Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-deployment"
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

resource "aws_security_group" "jitbit" {
  vpc_id      = data.aws_vpc.shared.id
  name        = format("hmpps-%s-%s-service", local.environment, local.application_name)
  description = "Security group for the ${local.application_name} service"
  tags        = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jitbit.id
}

resource "aws_security_group_rule" "alb" {
  description              = "Allow inbound traffic from ALB"
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.load_balancer_security_group.id
  security_group_id        = aws_security_group.jitbit.id
}

output "s3_bucket_app_deployment_name" {
  value = module.s3_bucket_app_deployment.bucket.id
}
