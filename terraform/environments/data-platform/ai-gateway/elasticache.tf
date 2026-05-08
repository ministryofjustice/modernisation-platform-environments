resource "aws_elasticache_replication_group" "ai_gateway" {
  replication_group_id = local.component_name
  description          = "Valkey cluster for AI Gateway"

  engine         = "valkey"
  engine_version = "8.0"
  node_type      = local.environment_configuration.elasticache_node_type

  num_cache_clusters         = local.is-production ? 2 : 1
  automatic_failover_enabled = local.is-production
  multi_az_enabled           = local.is-production

  subnet_group_name  = aws_elasticache_subnet_group.ai_gateway.name
  security_group_ids = [module.ai_gateway_elasticache_security_group.security_group_id]

  at_rest_encryption_enabled = true
  kms_key_id                 = data.aws_kms_key.general_shared.arn
  transit_encryption_enabled = true
  auth_token                 = random_password.elasticache.result

  parameter_group_name = "default.valkey8"

  tags = local.tags
}

resource "aws_elasticache_subnet_group" "ai_gateway" {
  name       = local.component_name
  subnet_ids = data.aws_subnets.eks-data.ids

  tags = local.tags
}

module "ai_gateway_elasticache_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/elasticache"

  secret_string = jsonencode({
    primary_endpoint_address = aws_elasticache_replication_group.ai_gateway.primary_endpoint_address
    auth_token               = random_password.elasticache.result
    port                     = tostring(aws_elasticache_replication_group.ai_gateway.port)
  })
}

module "ai_gateway_elasticache_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa" # v5.3.1

  name            = "${local.component_name}-elasticache"
  description     = "Security group for AI Gateway Valkey"
  vpc_id          = data.aws_vpc.eks.id
  use_name_prefix = false

  computed_ingress_with_cidr_blocks = [
    {
      rule        = "redis-tcp"
      description = "Allow Valkey access from EKS pods"
      cidr_blocks = data.aws_vpc.eks.cidr_block
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 1

  tags = local.tags
}
