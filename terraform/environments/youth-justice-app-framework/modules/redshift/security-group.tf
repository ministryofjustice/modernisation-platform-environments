module "redshift_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Redshift Serverless"
  description = "Control access to and from Redshift Servless"


  ingress_with_self = [{ rule = "all-all" }]
  egress_with_self  = [{ rule = "all-all" }]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = var.vpc_cidr
      description = "Redshift to Secrets Manager"
    }
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.postgres_security_group_id
      description              = "Redshift to Postgres"
    },
  ]
}

module "postgres_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.postgres_security_group_id
  create_sg         = false

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.redshift_sg.security_group_id
      description              = "Postgres from Redshift"
    },

  ]

}
