#------------------------------------------------------------------------------
# OpenSearch — full-text log search (ADR-017; Option B)
#
# One managed OpenSearch domain per business unit, each in the BU's own account.
# This file is deployed per workspace: each cloud-platform-<env> apply runs in
# that BU-environment account (MemberInfrastructureAccess), so a domain lands in
# each account. Live environments are sized larger than non-live (local.is_live).
#
# See architecture-decision-record/cp30/ADR-017-opensearch-deployment-model.md
# (cloud-platform repo). Scoped to cloud-platform-development for now via
# local.opensearch_host_workspaces — the first build proves the config in the
# development account before the per-BU rollout.
#
# Serverless is NOT used (ADR-017 D2): full managed OpenSearch everywhere.
#------------------------------------------------------------------------------

# Fine-grained access control master user: the platform-engineer SSO role, so
# platform engineers can reach OpenSearch Dashboards. Per-BU read-only mapping
# and full SSO/SAML federation are a follow-up (tracked on #8420); this gets a
# working, access-controlled domain stood up first.
locals {
  opensearch_master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_platform-engineer-admin_5e1838a3c5d27fc3"
}

resource "aws_opensearch_domain" "logs" {
  count = local.enable_opensearch ? 1 : 0

  domain_name    = local.opensearch_domain_name
  engine_version = local.opensearch_engine # pinned: OpenSearch_3.7 (ADR-017 D5)

  cluster_config {
    instance_type  = local.opensearch_instance
    instance_count = local.opensearch_data_nodes
    # Single-/dual-node to start; not production shard topology. Dedicated master
    # and zone awareness are a sizing follow-up once log volume is measured (#8420).
    zone_awareness_enabled   = false
    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = local.opensearch_ebs_gb
  }

  # FGAC prerequisites: encryption at rest, node-to-node encryption, HTTPS.
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Fine-grained access control, IAM master user = the SSO admin role.
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = local.opensearch_master_role_arn
    }
  }

  # Domain access policy — allow the master role. FGAC does the fine-grained part.
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.opensearch_master_role_arn }
      Action    = "es:*"
      Resource  = "arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
    }]
  })

  tags = merge(local.tags, {
    component = "observability"
  })
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint (null when not enabled for this workspace)."
  value       = local.enable_opensearch ? aws_opensearch_domain.logs[0].endpoint : null
}

output "opensearch_dashboards_endpoint" {
  description = "OpenSearch Dashboards endpoint."
  value       = local.enable_opensearch ? aws_opensearch_domain.logs[0].dashboard_endpoint : null
}
