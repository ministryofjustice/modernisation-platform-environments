resource "aws_msk_serverless_cluster" "cluster" {
  count        = contains(["development"], local.environment) ? 1 : 0
  cluster_name = local.cluster_name
  region       = data.aws_region.current.region

  vpc_config {
    subnet_ids         = data.aws_subnets.shared-private.ids
    security_group_ids = [aws_security_group.msk[0].id]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = merge(local.extended_tags, {
    name        = local.cluster_name,
    description = "POV MSK cluster"
  })
}

resource "aws_security_group" "msk" {
  count       = contains(["development"], local.environment) ? 1 : 0
  name_prefix = "${local.cluster_name}-sg"
  description = "Security group for MSK Serverless cluster"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.extended_tags, {
    name        = "${local.cluster_name}-sg",
    description = "Security group for MSK Serverless cluster"
  })

}

resource "aws_vpc_security_group_ingress_rule" "private_subnets" {
  for_each          = local.msk_sg_ingress_cidr
  security_group_id = aws_security_group.msk[0].id
  description       = "Allow inbound traffic from private subnet ${each.value}"
  from_port         = 9098
  to_port           = 9098
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}
