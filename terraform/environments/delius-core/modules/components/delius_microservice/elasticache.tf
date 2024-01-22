resource "aws_elasticache_subnet_group" "this" {
  count      = var.create_elasticache ? 1 : 0
  name       = "elasticache-subnet-group-${var.name}-${var.env_name}"
  subnet_ids = var.account_config.ordered_subnets.*.id
  tags       = var.tags
}

resource "aws_elasticache_cluster" "this" {
  count = var.create_elasticache ? 1 : 0

  cluster_id                 = "cluster-example"
  engine                     = var.elasticache_engine
  node_type                  = var.elasticache_node_type
  num_cache_nodes            = var.elasticache_num_cache_nodes
  parameter_group_name       = var.elasticache_parameter_group_name
  engine_version             = var.elasticache_engine_version
  port                       = var.elasticache_port
  subnet_group_name          = aws_elasticache_subnet_group.this[0].name
  auto_minor_version_upgrade = true
  final_snapshot_identifier  = var.elasticache_engine == "redis" ? "final-redis-${var.name}-${var.env_name}" : null
  maintenance_window         = var.maintenance_window
  security_group_ids         = [aws_security_group.elasticache[0].id]
}


resource "aws_security_group" "elasticache" {
  count       = var.create_elasticache ? 1 : 0
  name        = "${var.name}-elasticache-security-group"
  description = "controls access to elasticache"
  vpc_id      = var.account_config.shared_vpc_id

  ingress {
    protocol    = "tcp"
    description = "Allow elasticache traffic"
    from_port   = var.elasticache_port
    to_port     = var.elasticache_port
    security_groups = [
      var.account_config.bastion.bastion_security_group,
      var.ingress_security_groups
    ]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.env_name}-database_security_group"
    }
  )
}
