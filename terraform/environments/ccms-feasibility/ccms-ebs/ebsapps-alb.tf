# Shared load balancer access log bucket, managed in ccms-feasibility root
data "aws_s3_bucket" "lb_access_logs" {
  bucket = "${local.application_name}-${local.environment}-lb-access-logs"
}

module "alb" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/8800d60
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=8800d60"

  name               = "${local.component_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.ebsapps_alb.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].tg_apps_port

  stickiness = {
    enabled  = true
    duration = 3600
  }

  health_check = {
    path = "/"
  }

  enable_deletion_protection = false

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = "${local.component_name}-${local.env_label}"
  }

  tags = local.tags
}
