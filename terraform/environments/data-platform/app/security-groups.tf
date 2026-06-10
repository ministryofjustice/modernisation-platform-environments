module "app_rds_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v6.0.0" # v6.0.0

  name                   = "${local.component_name}-postgresql-rds"
  description            = "Security group for app RDS PostgreSQL"
  vpc_id                 = data.aws_vpc.eks.id
  use_name_prefix        = false
  revoke_rules_on_delete = true

  ingress_rules = {
    postgres_from_eks = {
      from_port   = 5432
      to_port     = 5432
      ip_protocol = "tcp"
      cidr_ipv4   = data.aws_vpc.eks.cidr_block
      description = "Allow PostgreSQL access from EKS pods"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
