module "ecs_sandbox" {
  count = local.is-development ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.0"

  name = "${local.application_name}-sandbox"

  tags = local.tags
}

module "s3_bucket_app_deployment_sandbox" {
  count = local.is-development ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-sandbox-deployment"
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

resource "aws_security_group" "jitbit_sandbox" {
  count = local.is-development ? 1 : 0

  vpc_id      = data.aws_vpc.shared.id
  name        = format("hmpps-%s-%s-service", "sandbox", local.application_name)
  description = "Security group for the ${local.application_name} service"
  tags        = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress_sandbox" {
  count = local.is-development ? 1 : 0

  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jitbit_sandbox[0].id
}

resource "aws_security_group_rule" "alb_sandbox" {
  count = local.is-development ? 1 : 0

  description              = "Allow inbound traffic from ALB"
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.load_balancer_security_group.id
  security_group_id        = aws_security_group.jitbit_sandbox[0].id
}

resource "aws_cloudwatch_log_group" "jitbit_sandbox" {
  count = local.is-development ? 1 : 0

  name              = format("%s-%s-ecs", local.application_name, "sandbox")
  retention_in_days = 30
}
