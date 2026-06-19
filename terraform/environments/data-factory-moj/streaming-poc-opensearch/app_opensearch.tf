module "opensearch" {
  count   = contains(["development"], local.environment) ? 1 : 0
  source  = "terraform-aws-modules/opensearch/aws"
  version = "~> 2.0"

  domain_name    = local.cluster_name
  engine_version = var.engine_version

  cluster_config = {
    instance_count        = var.instance_count
    instance_type         = var.instance_type
    dedicated_master_type = var.instance_type
  }

  advanced_security_options = {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options = {
      master_user_name     = random_string.master_username[0].result
      master_user_password = random_password.master_password[0].result
    }
  }

  vpc_options = {
    subnet_ids         = slice(data.aws_subnets.shared-private.ids, 0, 2)
    security_group_ids = [aws_security_group.opensearch[0].id]
  }

  access_policy_statements = {
    account = {
      effect = "Allow"
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
      actions   = ["es:*"]
      resources = ["arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${local.cluster_name}/*"]
    }
  }

  tags = merge(local.extended_tags, {
    name        = local.cluster_name,
    description = "POV opensearch cluster"
  })
}

resource "aws_security_group" "opensearch" {
  count       = contains(["development"], local.environment) ? 1 : 0
  name_prefix = "${local.cluster_name}-sg"
  description = "Security group for OpenSearch domain access"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.extended_tags, {
    name        = "{local.cluster_name}-sg",
    description = "Security group for OpenSearch domain access"
  })

}

resource "aws_vpc_security_group_ingress_rule" "opensearch_sg" {
  for_each          = local.opensearch_sg_ingress_cidr
  security_group_id = aws_security_group.opensearch[0].id
  description       = "Allow inbound traffic from private subnet ${each.value}"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}
