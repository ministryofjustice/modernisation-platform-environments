#------------------------------------------------------------------------------
# OpenSearch — full-text log search. One shared, managed domain per environment,
# FGAC on, audit logging to CloudWatch. Business units are kept apart inside the
# cluster (per-BU indexes + index-level roles), not by separate domains. Scoped to
# cloud-platform-development for now (the dev proof-of-concept).
#
# Public endpoint for now (no VPN to reach a private one); goes in-VPC later. The
# in-cluster parts (per-BU indexes, ISM, Fluent Bit write #8419) are phase 2.
#
# Rationale: architecture-decision-record/cp30/ADR-017-opensearch-deployment-model.md
#------------------------------------------------------------------------------

# FGAC master = platform-engineer SSO role, resolved by permission-set name (the
# ARN suffix is account-specific). Same lookup as cluster/eks-cluster.tf.
data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  opensearch_master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
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
  #checkov:skip=CKV_AWS_247:CMK deferred to production; dev PoC uses the aws/es key. See ADR-017.
  #checkov:skip=CKV_AWS_318:Dedicated master is deferred HA sizing, not the dev PoC. See ADR-017.
  #checkov:skip=CKV2_AWS_59:As CKV_AWS_318 — deferred HA sizing.
  #checkov:skip=CKV_AWS_137:Public on purpose for now (no VPN for a private endpoint); goes in-VPC later. See ADR-017.
  #checkov:skip=CKV_AWS_248:No SG — public, not in a VPC (as CKV_AWS_137).
  count = local.enable_opensearch ? 1 : 0

  domain_name    = local.opensearch_domain_name
  engine_version = local.opensearch_engine # pinned OpenSearch_3.7

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
