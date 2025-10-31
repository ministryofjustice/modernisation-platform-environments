
module "tableau_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Tableau Server"
  description = "Control access to and from Tableau Servers"

  ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.alb_sg.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = var.management_server_sg_id
    },
    {
      rule                     = "http-80-tcp"
      source_security_group_id = var.management_server_sg_id
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = var.management_server_sg_id
    },
    {
      from_port                = 8850
      to_port                  = 8850
      protocol                 = "tcp"
      source_security_group_id = var.management_server_sg_id
    },

  ]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "Tableau server outbound access for sofware updates."
    },
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "ldap-tcp"
      source_security_group_id = var.directory_service_sg_id
    },
    {
      rule                     = "ldaps-tcp"
      source_security_group_id = var.directory_service_sg_id
    },
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.postgresql_sg_id
    },
    {
      rule                     = "redshift-tcp"
      source_security_group_id = var.redshift_sg_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = var.yjsm_sg_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = var.esb_sg_id
    }
  ]
}

module "directory_service_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.directory_service_sg_id
  create_sg         = false

  ingress_with_source_security_group_id = [
    {
      rule                     = "ldap-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
    {
      rule                     = "ldaps-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
  ]
}

module "management_service_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.management_server_sg_id
  create_sg         = false

  egress_with_source_security_group_id = [
    {
      to_port                  = "8850"
      from_port                = "8850"
      protocol                 = "tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = var.yjsm_sg_id
    }
  ]
}

module "postgresql_sg" {
  source = "./add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.tableau_sg.security_group_id
  target_sg_id = var.postgresql_sg_id
  rule         = "postgresql-tcp"
  description  = "Inbound from Tableau"
}

module "redshift_sg" {
  source = "./add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.tableau_sg.security_group_id
  target_sg_id = var.redshift_sg_id
  rule         = "redshift-tcp"
  description  = "Redshift from Tableau Server."

}
