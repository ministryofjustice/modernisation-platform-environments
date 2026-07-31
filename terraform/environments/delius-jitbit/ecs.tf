moved {
  from = module.ecs.module.ecs_cluster.aws_ecs_cluster.default[0]
  to   = module.ecs.aws_ecs_cluster.this
}

module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=948cb6a1d0d08448fd53f195c0522ed35bbf4242" # v6.0.0

  name = "hmpps-${local.environment}-${local.application_name}"

  tags = local.tags
}

#Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-deployment"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

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
  #checkov:skip=CKV_AWS_382:"Required for ECS tasks to access external services"
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
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  name              = format("%s-ecs", local.application_name)
  retention_in_days = 30
  kms_key_id        = data.aws_kms_key.general_shared.arn
}

output "s3_bucket_app_deployment_name" {
  value = module.s3_bucket_app_deployment.bucket.id
}
