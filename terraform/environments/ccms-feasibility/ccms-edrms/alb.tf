module "alb" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/bdb2deff32a3789cd0bbbf617d56660b1b94877b
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=bdb2deff32a3789cd0bbbf617d56660b1b94877b"

  name               = "${local.component_name}-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = aws_acm_certificate_validation.external.certificate_arn
  target_port        = local.application_data.accounts[local.environment].edrms_server_port

  health_check = {
    path = "/actuator/health"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  tags = local.tags
}
