module "nlb_admin" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0"

  name               = "${local.component_name}-admin-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb_admin.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].admin_server_port

  health_check = {
    protocol = "HTTP"
    path     = "/weblogic/ready"
  }

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  tags = local.tags
}

module "nlb_managed" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/nlb?ref=c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0"

  name               = "${local.component_name}-managed-${local.env_label}"
  subnet_ids         = data.aws_subnets.shared-private.ids
  security_group_ids = [aws_security_group.alb_managed.id]
  vpc_id             = data.aws_vpc.shared.id
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  target_port        = local.application_data.accounts[local.environment].managed_server_port

  enable_deletion_protection = local.application_data.accounts[local.environment].alb_deletion_protection

  tags = local.tags
}
