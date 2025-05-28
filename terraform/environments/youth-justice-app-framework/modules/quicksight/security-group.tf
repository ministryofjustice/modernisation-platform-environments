
module "quicksight_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Quicksight"
  description = "Control Quicjsight VPC access"

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-tcp"
      source_security_group_id = var.redshift_sg_id
    },
    {
      rule                     = "all-tcp"
      source_security_group_id = var.postgresql_sg_id
    },
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.postgresql_sg_id
    },
    {
      rule                     = "redshift-tcp"
      source_security_group_id = var.redshift_sg_id
    },
  ]
}

module "postgresql_sg" {
  source = "../tableau/add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.quicksight_sg.security_group_id
  target_sg_id = var.postgresql_sg_id
  rule         = "postgresql-tcp"
  description  = "Inbound from Quicksight"
}

module "redshift_sg" {
  source = "../tableau/add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.quicksight_sg.security_group_id
  target_sg_id = var.redshift_sg_id
  rule         = "redshift-tcp"
  description  = "Redshift from Quicksight"

}
