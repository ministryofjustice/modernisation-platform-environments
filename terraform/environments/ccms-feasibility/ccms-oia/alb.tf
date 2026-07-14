module "alb_opahub" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

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

  tags = local.tags
}

module "alb_connector" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

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

  tags = local.tags
}

module "alb_adaptor" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alb?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

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

  tags = local.tags
}
