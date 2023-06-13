locals {
  openldap_name     = format("%s-openldap", local.application_name)
  openldap_nlb_name = format("%s-nlb", local.openldap_name)
  openldap_nlb_tags = merge(
    local.tags,
    {
      Name = local.openldap_nlb_name
    }
  )

  openldap_protocol = "TCP"
}
resource "aws_lb" "ldap" {
  name                       = local.openldap_nlb_name
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = data.aws_subnets.shared-private.ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs {
    bucket  = module.s3_bucket_nlb_logs.bucket.id
    prefix  = format("%s/%s", local.application_name, local.openldap_name)
    enabled = true
  }

  tags = local.openldap_nlb_tags
}


module "s3_bucket_nlb_logs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-openldap-nlb-logs"
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

resource "aws_lb_listener" "ldap" {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.openldap_port
  protocol          = local.openldap_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }

  tags = local.openldap_nlb_tags
}

resource "aws_lb_target_group" "ldap" {
  name     = local.openldap_name
  port     = local.openldap_port
  protocol = local.openldap_protocol
  vpc_id   = data.aws_vpc.shared.id

  target_type          = "ip"
  deregistration_delay = "30"
  tags = merge(
    local.tags,
    {
      Name = local.openldap_name
    }
  )
}
