module "llm_gateway_rds_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa" # v5.3.1

  name            = "${local.component_name}-rds"
  description     = "Security group for LiteLLM RDS PostgreSQL"
  vpc_id          = data.aws_vpc.shared.id
  use_name_prefix = false

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      description              = "Allow PostgreSQL access from EKS cluster"
      source_security_group_id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  tags = local.tags
}
