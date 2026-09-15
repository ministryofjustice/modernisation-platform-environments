module "alb" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/08ee30f
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=08ee30f"

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

  tags = local.tags
}
