
module "destination_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.target_sg_id
  create_sg         = false

  ingress_with_source_security_group_id = [
    {
      rule                     = var.rule
      source_security_group_id = var.source_sg_id
      description              = var.description
    },

  ]

}
