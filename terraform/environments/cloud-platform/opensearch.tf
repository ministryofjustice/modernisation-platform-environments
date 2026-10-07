#------------------------------------------------------------------------------
# OpenSearch — full-text log search. One shared, managed domain per environment,
# private (in-VPC), FGAC on, audit logging to CloudWatch. Business units are kept
# apart inside the cluster (per-BU indexes + index-level roles), not by separate
# domains. Scoped to cloud-platform-development for now (the dev proof-of-concept).
#
# The in-cluster parts — per-BU indexes, ISM lifecycle, Fluent Bit's write
# mapping (#8419) — need the OpenSearch provider and are not in this file yet.
#
# Design + rationale: architecture-decision-record/cp30/ADR-017-opensearch-deployment-model.md
#------------------------------------------------------------------------------

# FGAC master user: the platform-engineer SSO role.
locals {
  opensearch_master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_platform-engineer-admin_5e1838a3c5d27fc3"
}

# VPC + private subnets. Looked up by tag because the VPC is in the `network`
# component (separate state), so we can't reference the module.
data "aws_vpc" "opensearch" {
  count = local.enable_opensearch ? 1 : 0

  tags = {
    Name = local.opensearch_vpc_name
  }
}

data "aws_subnets" "opensearch_private" {
  count = local.enable_opensearch ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.opensearch[0].id]
  }

  tags = {
    SubnetType = "Private"
  }
}

# HTTPS in from inside the VPC only.
resource "aws_security_group" "opensearch" {
  count = local.enable_opensearch ? 1 : 0

  name        = "${local.opensearch_domain_name}-opensearch"
  description = "OpenSearch domain ${local.opensearch_domain_name} - HTTPS from within the VPC"
  vpc_id      = data.aws_vpc.opensearch[0].id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.opensearch[0].cidr_block]
  }

  tags = merge(local.tags, {
    Name      = "${local.opensearch_domain_name}-opensearch"
    component = "observability"
  })
}

# Audit log group. Under /aws/vendedlogs/ so one prefix-wide resource policy
# (below) covers it — CloudWatch allows only 10 resource policies per Region.
resource "aws_cloudwatch_log_group" "opensearch_audit" {
  #checkov:skip=CKV_AWS_158:Per ADR-017, CloudWatch is the short-retention operational tier (default AES-256); customer-managed KMS is reserved for the S3 archive. Matches the Auto Mode vended-logs group (cluster/eks-cluster.tf).
  count = local.enable_opensearch ? 1 : 0

  name              = local.opensearch_audit_log_group
  retention_in_days = local.opensearch_audit_retention_days

  tags = merge(local.tags, {
    component = "observability"
  })
}

# Allow the OpenSearch service to write to the vended-logs groups. SourceAccount
# /SourceArn conditions guard against the confused-deputy problem.
data "aws_iam_policy_document" "opensearch_audit" {
  count = local.enable_opensearch ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vendedlogs/opensearch/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/*"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_audit" {
  count = local.enable_opensearch ? 1 : 0

  policy_name     = "opensearch-vendedlogs"
  policy_document = data.aws_iam_policy_document.opensearch_audit[0].json
}

resource "aws_opensearch_domain" "logs" {
  #checkov:skip=CKV_AWS_247:Dev PoC uses the AWS-managed aws/es key; a customer-managed key comes with the production shared cluster. See ADR-017.
  #checkov:skip=CKV_AWS_318:Dedicated master nodes are a deliberate deferral for the dev PoC; HA sizing (3 masters, zone awareness) is the measured follow-up for the production cluster. See ADR-017.
  #checkov:skip=CKV2_AWS_59:Same as CKV_AWS_318 — dedicated master is part of the deferred HA sizing, not the small dev PoC. See ADR-017.
  count = local.enable_opensearch ? 1 : 0

  domain_name    = local.opensearch_domain_name
  engine_version = local.opensearch_engine # pinned: OpenSearch_3.7 (ADR-017 D5)

  cluster_config {
    instance_type  = local.opensearch_instance
    instance_count = local.opensearch_data_nodes
    # Master + zone awareness are the deferred HA sizing (see ADR-017 / Checkov skips).
    zone_awareness_enabled   = false
    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = local.opensearch_ebs_gb
  }

  # One subnet while zone awareness is off (AWS rejects multiple); widen to the
  # AZ count when multi-AZ is enabled.
  vpc_options {
    subnet_ids         = slice(data.aws_subnets.opensearch_private[0].ids, 0, 1)
    security_group_ids = [aws_security_group.opensearch[0].id]
  }

  # Encryption + HTTPS: required for FGAC.
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10" # TLS 1.3 + 1.2 PFS
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = local.opensearch_master_role_arn
    }
  }

  # Allow the master role; FGAC does the fine-grained part.
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.opensearch_master_role_arn }
      Action    = "es:*"
      Resource  = "arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
    }]
  })

  # depends_on below: the resource policy must exist before the domain publishes.
  log_publishing_options {
    log_type                 = "AUDIT_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_audit[0].arn
    enabled                  = true
  }

  tags = merge(local.tags, {
    component = "observability"
  })

  depends_on = [aws_cloudwatch_log_resource_policy.opensearch_audit]
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint (null when not enabled for this workspace)."
  value       = local.enable_opensearch ? aws_opensearch_domain.logs[0].endpoint : null
}

output "opensearch_dashboards_endpoint" {
  description = "OpenSearch Dashboards endpoint."
  value       = local.enable_opensearch ? aws_opensearch_domain.logs[0].dashboard_endpoint : null
}
