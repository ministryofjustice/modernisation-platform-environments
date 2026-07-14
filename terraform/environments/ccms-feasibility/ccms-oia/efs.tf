module "efs" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/efs?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  name = "${local.component_name}-${local.env_label}"
  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id,
  ]
  security_group_ids = [aws_security_group.efs.id]
  kms_key_id         = data.aws_kms_key.general_shared.arn
  tags               = local.tags
}
