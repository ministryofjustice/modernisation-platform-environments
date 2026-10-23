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

# Identity Center lives in the org management account, so read via sso-readonly.
data "aws_ssoadmin_instances" "opensearch" {
  count    = local.opensearch_idc_enabled ? 1 : 0
  provider = aws.sso-readonly
}

locals {
  # The UI dashboardAdmin check matches on group ID. The IDs are hardcoded
  # because the ModernisationPlatformSSOReadOnly role returns
  # ResourceNotFoundException when calling GetGroupId despite having
  # identitystore:Get*. This mirrors the same workaround (and the same two
  # groups) used for AMG RBAC in amg.tf and for ArgoCD RBAC in cluster/locals.tf.
  # TODO: switch back to a data.aws_identitystore_group lookup once the read role
  # permissions are fixed.
  opensearch_ui_admin_group_ids_list = [
    "664252b4-7021-701e-49b9-6c46ccc7899e", # cloud-platform-engineers
    "7682a204-00f1-7031-257e-713bb28289c6", # container-platform-aws
  ]
  opensearch_ui_admin_group_ids = join(",", local.opensearch_ui_admin_group_ids_list)
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

  # Identity Center SSO. GroupName so group membership drives FGAC roles (#8592).
  dynamic "identity_center_options" {
    for_each = local.opensearch_idc_enabled ? [1] : []
    content {
      enabled_api_access           = true
      identity_center_instance_arn = data.aws_ssoadmin_instances.opensearch[0].arns[0]
      roles_key                    = "GroupName"
      subject_key                  = "Email"
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

#------------------------------------------------------------------------------
# OpenSearch UI application — the browser sign-in surface. identity_center_options
# above only enables IdC; it does not create a UI to log into. This is that UI,
# with the domain as its data source and Identity Center sign-in. See ADR-017.
#------------------------------------------------------------------------------

# Role the UI application assumes to reach the domain and resolve IdC groups
resource "aws_iam_role" "opensearch_ui_app" {
  count = local.opensearch_idc_enabled ? 1 : 0

  name = "${terraform.workspace}-opensearch-ui-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "application.opensearchservice.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        # Lets the UI attach the signed-in user's Identity Center identity to domain
        # requests. Must be the AWS-defined context provider — any other value makes
        # every UI data request fail with a 400 (sign-in still works).
        Effect    = "Allow"
        Principal = { Service = "application.opensearchservice.amazonaws.com" }
        Action    = "sts:SetContext"
        Condition = {
          "ForAllValues:ArnEquals" = {
            "sts:RequestContextProviders" = "arn:aws:iam::aws:contextProvider/IdentityCenter"
          }
        }
      }
    ]
  })

  tags = merge(local.tags, { component = "observability" })
}

resource "aws_iam_role_policy" "opensearch_ui_app" {
  count = local.opensearch_idc_enabled ? 1 : 0

  name = "opensearch-ui-app"
  role = aws_iam_role.opensearch_ui_app[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Resolve the signed-in user's IdC groups, only when called via OpenSearch.
        Sid      = "IdentityStoreLookup"
        Effect   = "Allow"
        Action   = ["identitystore:DescribeUser", "identitystore:ListGroupMembershipsForMember", "identitystore:DescribeGroup"]
        Resource = "*"
        Condition = {
          "ForAnyValue:StringEquals" = { "aws:CalledViaLast" = "es.amazonaws.com" }
        }
      },
      {
        Sid      = "OpenSearchDomainAccess"
        Effect   = "Allow"
        Action   = ["es:ESHttp*"]
        Resource = "${aws_opensearch_domain.logs[0].arn}/*"
      }
    ]
  })
}

resource "aws_opensearch_application" "logs" {
  count = local.opensearch_idc_enabled ? 1 : 0

  name = local.opensearch_domain_name # <=30 chars, lowercase/nums/hyphens — the domain name already fits

  data_source {
    data_source_arn         = aws_opensearch_domain.logs[0].arn
    data_source_description = "Cloud Platform shared log domain"
  }

  iam_identity_center_options {
    enabled                                      = true
    iam_identity_center_instance_arn             = data.aws_ssoadmin_instances.opensearch[0].arns[0]
    iam_role_for_identity_center_application_arn = aws_iam_role.opensearch_ui_app[0].arn
  }

  # UI admin by Identity Center group — same admin groups as Grafana. The IDs
  # are set in the locals above. Dynamic so the block is only sent when IdC is
  # enabled — app_config value must be 1+ chars, so an empty block would fail.
  dynamic "app_config" {
    for_each = local.opensearch_idc_enabled ? [1] : []
    content {
      key   = "opensearchDashboards.dashboardAdmin.groups"
      value = local.opensearch_ui_admin_group_ids
    }
  }

  tags = merge(local.tags, { component = "observability" })
}

# Assign the admin groups to the IdC application. The app requires assignment, so
# without this Identity Center passes no group claims and every sign-in fails with
# "not authorized to access dashboards" — even with the groups set in app_config.
resource "aws_ssoadmin_application_assignment" "opensearch_ui_admin" {
  for_each = local.opensearch_idc_enabled ? toset(local.opensearch_ui_admin_group_ids_list) : []

  application_arn = aws_opensearch_application.logs[0].iam_identity_center_options[0].iam_identity_center_application_arn
  principal_id    = each.value
  principal_type  = "GROUP"
}

output "opensearch_ui_app_endpoint" {
  description = "OpenSearch UI application URL for browser sign-in (null when IdC not enabled)."
  value       = local.opensearch_idc_enabled ? aws_opensearch_application.logs[0].endpoint : null
}
