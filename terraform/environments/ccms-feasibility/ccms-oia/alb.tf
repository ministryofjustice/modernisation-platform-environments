# Shared load balancer access log bucket, managed in ccms-feasibility root
data "aws_s3_bucket" "lb_access_logs" {
  bucket = "${local.application_name}-lb-access-logs"
}

module "alb_opahub" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=10d2292"

  name               = "${local.opahub_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb_opahub.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].opa_server_port

  health_check = {
    path = "/"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = local.opahub_name
  }

  alarms = {
    topic_arn         = data.aws_sns_topic.alerts.arn
    min_healthy_hosts = local.application_data.accounts[local.environment].opa_app_count # same as the ECS service's desired_count
  }

  tags = local.tags
}

module "alb_connector" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=10d2292"

  name               = "${local.connector_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb_connector.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].connector_server_port

  health_check = {
    path = "/actuator/health"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = local.connector_name
  }

  alarms = {
    topic_arn         = data.aws_sns_topic.alerts.arn
    min_healthy_hosts = local.application_data.accounts[local.environment].connector_desired_count # same as the ECS service's desired_count
  }

  tags = local.tags
}

module "alb_adaptor" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=10d2292"

  name               = "${local.adaptor_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb_adaptor.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].adaptor_server_port

  health_check = {
    path = "/actuator/health"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  access_logs = {
    bucket = data.aws_s3_bucket.lb_access_logs.id
    prefix = local.adaptor_name
  }

  alarms = {
    topic_arn         = data.aws_sns_topic.alerts.arn
    min_healthy_hosts = local.application_data.accounts[local.environment].adaptor_desired_count # same as the ECS service's desired_count
  }

  tags = local.tags
}
