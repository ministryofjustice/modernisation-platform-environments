module "ecs" {
  source = "github.com/ministryofjustice/terraform-ecs//cluster?ref=3c9a5a0762c7b2dbff6608e606a2784c8a4ef9c4"

  environment = local.environment
  name        = local.application_name

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

resource "aws_cloudwatch_log_group" "jitbit" {
  name              = format("%s-ecs", local.application_name)
  retention_in_days = 30
}

output "s3_bucket_app_deployment_name" {
  value = module.s3_bucket_app_deployment.bucket.id
}
