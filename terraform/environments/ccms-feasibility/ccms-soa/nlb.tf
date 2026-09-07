module "nlb_admin" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/fbec9c4550470ccbe5818996867aebca9e01fe1b
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=fbec9c4550470ccbe5818996867aebca9e01fe1b"

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

  tags = local.tags
}

module "nlb_managed" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/fbec9c4550470ccbe5818996867aebca9e01fe1b
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=fbec9c4550470ccbe5818996867aebca9e01fe1b"

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

  tags = local.tags
}
