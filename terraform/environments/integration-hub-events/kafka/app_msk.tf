resource "aws_msk_cluster" "cluster" {
  count                  = contains(local.deploy_to, local.environment) ? 1 : 0
  cluster_name           = local.cluster_name
  kafka_version          = "3.8.x"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = slice(sort(data.aws_subnets.shared-private.ids), 0, 2) # MSK needs 2 or 3 subnets, and one broker per subnet here
    security_groups = [aws_security_group.msk[0].id]

    storage_info {
      ebs_storage_info {
        volume_size = 1
      }
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  tags = merge(local.extended_tags, {
    name        = local.cluster_name,
    description = "Integration Hub Events MSK cluster"
  })
}

resource "aws_security_group" "msk" {
  #checkov:skip=CKV2_AWS_5:Skipping because this SG is attached via the MSK vpc_config block
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name_prefix = "${local.cluster_name}-sg"
  description = "Security group for MSK cluster"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.extended_tags, {
    Name        = "${local.cluster_name}-sg",
    description = "Security group for MSK cluster"
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

# The Lambda event source mapping poller runs in the cluster subnets using this
# security group, so it needs to reach the brokers and, for IAM auth, STS.
resource "aws_vpc_security_group_ingress_rule" "msk_self" {
  count                        = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id            = aws_security_group.msk[0].id
  description                  = "Allow broker traffic from members of this security group"
  from_port                    = 9098
  to_port                      = 9098
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.msk[0].id
}

resource "aws_vpc_security_group_egress_rule" "msk_self" {
  count                        = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id            = aws_security_group.msk[0].id
  description                  = "Allow broker traffic to members of this security group"
  from_port                    = 9098
  to_port                      = 9098
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.msk[0].id
}

resource "aws_vpc_security_group_egress_rule" "msk_https" {
  #checkov:skip=CKV_AWS_382:HTTPS egress is required for the Lambda poller to reach STS and the Lambda service
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.msk[0].id
  description       = "Allow HTTPS for STS and Lambda service calls"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
