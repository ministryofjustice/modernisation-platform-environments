module "efs" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/efs?ref=c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0"

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
