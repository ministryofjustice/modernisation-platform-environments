resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "allow access to Redis"
  vpc_id      = local.account_info.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "vcms-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = local.tags
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name        = "vcms-redis-subnets"
  description = "Subnet group for VCMS Redis"
  subnet_ids  = local.account_config.private_subnet_ids
}