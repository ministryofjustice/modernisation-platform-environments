module "alb" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/546ba54
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=546ba54"

  name               = "${local.component_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].pui_server_port
  target_type        = "ip"

  health_check = {
    path = "/civil/actuator/health"
  }

  stickiness = {
    enabled  = true
    duration = 7200
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  tags = local.tags
}
