resource "aws_service_discovery_private_dns_namespace" "vcms" {
  name = "vcms.local"

  vpc = local.account_info.vpc_id

  tags = local.tags
}

resource "aws_service_discovery_service" "frontend" {
  name = "frontend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.vcms.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
  
  tags = local.tags
}
