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
# Architecture-review decisions baked in here:
#   - Private domain in the VPC's private subnets (not internet-facing), reached
#     over VPN / transit gateway / VPC endpoints like the EKS clusters.
#   - Audit logging on, published to a CloudWatch /aws/vendedlogs/ group.
#   - Retention set per BU (local.opensearch_audit_retention_days), not global.
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

#------------------------------------------------------------------------------
# VPC lookup — the domain goes in the private subnets of the workspace VPC.
# The VPC lives in the `network` component (separate state), so look it up by
# tag rather than reference the module. See locals.opensearch_vpc_name.
#------------------------------------------------------------------------------
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

# Security group for the domain's VPC endpoints. HTTPS in from inside the VPC
# only; the private network (VPN / transit gateway) is what reaches it.
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

#------------------------------------------------------------------------------
# Audit logging -> CloudWatch Logs.
#
# The log group sits under /aws/vendedlogs/ so a single broad resource policy
# can cover every per-BU domain. CloudWatch Logs allows only 10 resource
# policies per Region, so a per-domain policy would not scale to 22 clusters.
# (AWS: "Monitoring OpenSearch logs with Amazon CloudWatch Logs".)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "opensearch_audit" {
  #checkov:skip=CKV_AWS_158:Per ADR-017, CloudWatch is the short-retention operational tier (default AES-256); customer-managed KMS is reserved for the S3 archive. Matches the Auto Mode vended-logs group (cluster/eks-cluster.tf).
  count = local.enable_opensearch ? 1 : 0

  name              = local.opensearch_audit_log_group
  retention_in_days = local.opensearch_audit_retention_days

  tags = merge(local.tags, {
    component = "observability"
  })
}

# Let the OpenSearch service write to any OpenSearch vended-logs group in this
# account/region. One policy, wildcard prefix, so it covers future domains too.
# SourceAccount/SourceArn conditions guard against the confused-deputy problem.
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
  #checkov:skip=CKV_AWS_247:Dev PoC uses the AWS-managed aws/es key. The per-BU shared KMS key (alias/general-<bu>) lives in core-shared-services-production, not the development account, so a customer-managed key comes with the per-BU rollout. See ADR-017.
  #checkov:skip=CKV_AWS_318:Dedicated master nodes are a deliberate deferral for the dev PoC; HA sizing (3 masters, zone awareness) is the measured follow-up before per-BU rollout. See ADR-017.
  #checkov:skip=CKV2_AWS_59:Same as CKV_AWS_318 — dedicated master is part of the deferred HA sizing, not the single-node dev PoC. See ADR-017.
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

  # Private domain: lives in the VPC's private subnets, reachable only over the
  # private network (VPN / transit gateway / VPC endpoints), not the internet.
  # Subnet count follows zone awareness, not node count: one subnet while zone
  # awareness is off (AWS rejects multiple subnets otherwise). Widen this to the
  # AZ count when multi-AZ is turned on (sizing follow-up, #8420).
  vpc_options {
    subnet_ids         = slice(data.aws_subnets.opensearch_private[0].ids, 0, 1)
    security_group_ids = [aws_security_group.opensearch[0].id]
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

  # Audit logging on (architecture review). Needs FGAC, which is enabled above.
  # The resource policy must exist before the domain can publish.
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
