# Shared load balancer access log bucket, managed in ccms-feasibility root
data "aws_s3_bucket" "lb_access_logs" {
  bucket = "${local.application_name}-lb-access-logs"
}

module "nlb_admin" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=10d2292"

  name               = "${local.component_name}-admin-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.nlb_admin.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].admin_ssl_port

  target_group_protocol   = "TLS"
  enable_port_80_listener = false

  health_check = {
    protocol = "HTTPS"
    path     = "/weblogic/ready"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].nlb_deletion_protection

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = "${local.component_name}-admin"
  }

  tags = local.tags

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}

module "nlb_managed" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=10d2292"

  name               = "${local.component_name}-managed-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.nlb_managed.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].managed_ssl_port

  target_group_protocol   = "TLS"
  enable_port_80_listener = false

  health_check = {
    protocol = "HTTPS"
    path     = "/weblogic/ready"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].nlb_deletion_protection

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = "${local.component_name}-managed"
  }

  tags = local.tags

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}
