data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.eu-west-2.s3"]
  }
}

module "redshift_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Redshift Serverless"
  description = "Control access to and from Redshift Servless"


  ingress_with_self = [{ rule = "all-all" }]
  egress_with_self  = [{ rule = "all-all" }]

  ingress_with_source_security_group_id = [
    {
      rule                     = "redshift-tcp"
      source_security_group_id = var.management_server_sg_id
      description              = "Redshift from Management Servers"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = var.vpc_cidr
      description = "Redshift to Secrets Manager"
    },
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.postgres_security_group_id
      description              = "Redshift to Postgres"
    },
  ]

}

resource "aws_vpc_security_group_egress_rule" "redshift_to_s3" {
  security_group_id = module.redshift_sg.security_group_id
  to_port           = 443
  from_port         = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
  description       = "Redshift to S3"
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


module "mgmt_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.management_server_sg_id
  create_sg         = false

  egress_with_source_security_group_id = [
    {
      rule                     = "redshift-tcp"
      source_security_group_id = module.redshift_sg.security_group_id
      description              = "Management Servers to Redshift"
    },

  ]

}