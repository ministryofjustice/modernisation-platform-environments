module "ai_gateway_elasticache" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-elasticache.git?ref=ac0f1b9044db9f9ff9e6726d6f77530a8624b27d" # v1.11.0

  replication_group_id = local.component_name
  description          = "Valkey cluster for AI Gateway"

  engine         = "valkey"
  engine_version = "9.0"
  node_type      = local.environment_configuration.elasticache_node_type

  num_cache_clusters         = local.is-production ? 2 : 1
  automatic_failover_enabled = local.is-production
  multi_az_enabled           = local.is-production

  subnet_ids = data.aws_subnets.eks-data.ids

  at_rest_encryption_enabled = true
  kms_key_arn                = data.aws_kms_key.general_shared.arn
  transit_encryption_enabled = true
  auth_token                 = random_password.elasticache.result

  parameter_group_name = "default.valkey9"

  # Security group
  vpc_id                         = data.aws_vpc.eks.id
  security_group_name            = "${local.component_name}-elasticache"
  security_group_use_name_prefix = false
  security_group_description     = "Security group for AI Gateway Valkey"
  security_group_rules = {
    ingress_valkey = {
      description = "Allow Valkey access from EKS pods"
      cidr_ipv4   = data.aws_vpc.eks.cidr_block
    }
  }

  log_delivery_configuration = {
    slow_log = {
      destination      = module.ai_gateway_elasticache_slow_log_group.cloudwatch_log_group_name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
    engine_log = {
      destination      = module.ai_gateway_elasticache_engine_log_group.cloudwatch_log_group_name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }
  }
}

module "ai_gateway_elasticache_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/elasticache"

  secret_string = jsonencode({
    primary_endpoint_address = module.ai_gateway_elasticache.replication_group_primary_endpoint_address
    auth_token               = random_password.elasticache.result
    port                     = tostring(module.ai_gateway_elasticache.replication_group_port)
  })
}
