resource "aws_opensearch_domain" "logs" {
  domain_name    = "observability-platform-logs"
  engine_version = "OpenSearch_2.11"

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.query.bool.max_clause_count"    = 3000
    "override_main_response_version"         = "true"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.os_access_role_logs.arn
    }
  }

  cluster_config {
    instance_type            = "r6g.xlarge.search"
    instance_count           = "3"
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }

    warm_count   = 3
    warm_enabled = true
    warm_type    = "ultrawarm1.medium.search"

    cold_storage_options {
      enabled = true
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "3072"
    iops        = "16000" # limit is 16,000 https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
    throughput  = "593"   # Throughput scales proportionally up. iops x 0.25 (maximum 4,000) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose.html 
  }

  domain_endpoint_options {
    enforce_https           = true
    tls_security_policy     = "Policy-Min-TLS-1-2-2019-07" # default to TLS 1.2
    custom_endpoint_enabled = false
    # custom_endpoint_certificate_arn = module.acm_logs.acm_certificate_arn
    # custom_endpoint                 = "logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}" // TODO: update this
  }

  access_policies = null

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.logs.key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = {
    Domain = local.logs_domain
  }
}

resource "aws_opensearch_domain_policy" "logs" {
  domain_name     = aws_opensearch_domain.logs.domain_name
  access_policies = data.aws_iam_policy_document.logs.json
}

resource "elasticsearch_opensearch_ism_policy" "ism_policy_logs" {
  provider  = elasticsearch.logs
  policy_id = "hot-warm-cold-delete"
  body = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {
    timestamp_field   = "@timestamp"
    warm_transition   = "14d"
    cold_transition   = "30d"
    delete_transition = "366d"
    index_pattern     = jsonencode(local.index_pattern_logs)
  })

  depends_on = [
    aws_opensearch_domain_saml_options.logs,
  ]
}

# Create a role mapping
resource "elasticsearch_opensearch_roles_mapping" "all_access_logs" {
  provider    = elasticsearch.logs
  role_name   = "all_access"
  description = "Mapping AWS IAM roles to ES role all_access"
  backend_roles = concat([
    "webops",
    aws_iam_role.os_access_role_logs.arn,
  ], values(data.aws_eks_node_group.current)[*].node_role_arn) // TODO: update this

  // Permissions to manager-concourse in order to run logging tests
  users = ["arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"]
  depends_on = [
    aws_opensearch_domain_saml_options.logs,
  ]
}

resource "elasticsearch_opensearch_roles_mapping" "security_manager_logs" {
  provider    = elasticsearch.logs
  role_name   = "security_manager"
  description = "Mapping AWS IAM roles to ES role security_manager"
  backend_roles = [
    "webops",
    aws_iam_role.os_access_role_logs.arn,
  ]

  users = [
    "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse",
    "arn:aws:iam::754256621582:user/JaskaranSarkaria",
    "arn:aws:iam::754256621582:user/PoornimaKrishnasamy",
    "arn:aws:iam::754256621582:user/SteveWilliams",
    "arn:aws:iam::754256621582:user/JakeMulley",
    "arn:aws:iam::754256621582:user/SabluMiah",
    "arn:aws:iam::754256621582:user/TomSmith",
    "arn:aws:iam::754256621582:user/KyTruong"
  ]

  depends_on = [
    aws_opensearch_domain_saml_options.logs,
  ]
}

# Prevent document security overriding webops role by explicitly allowing webops to view all
resource "elasticsearch_opensearch_role" "webops_logs" {
  provider    = elasticsearch.logs
  role_name   = "webops"
  description = "role for all webops github users"

  cluster_permissions = ["*"]

  index_permissions {
    index_patterns          = ["*"]
    allowed_actions         = ["cluster_all", "indices_all", "unlimited"]
    document_level_security = "{\"match_all\": {}}"
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_write"]
  }
}

resource "elasticsearch_opensearch_roles_mapping" "webops_logs" {
  provider      = elasticsearch.logs
  role_name     = "webops"
  description   = "Mapping AWS IAM roles to ES role webops"
  backend_roles = ["webops"]
  depends_on = [
    aws_opensearch_domain_saml_options.logs,
    elasticsearch_opensearch_role.webops_logs
  ]
}

resource "elasticsearch_opensearch_role" "all_org_members_logs" {
  role_name   = "all_org_members"
  description = "role for all moj github users"

  cluster_permissions = ["search", "data_access", "read", "opensearch_dashboards_all_read", "get"]

  index_permissions {
    index_patterns  = ["*"]
    allowed_actions = ["read", "search", "data_access"]
  }

  index_permissions {
    index_patterns  = ["live_k8s_modsec_ingress-*"]
    allowed_actions = ["read", "search", "data_access"]

    document_level_security = "{\"terms\": { \"github_teams.keyword\": [$${user.roles}]}}"
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_read"]
  }
}

resource "elasticsearch_opensearch_roles_mapping" "all_org_members_logs" {
  role_name     = "all_org_members"
  description   = "Mapping AWS IAM roles to ES role all_org_members"
  backend_roles = ["all-org-members"]
  depends_on = [
    aws_opensearch_domain_saml_options.logs,
    elasticsearch_opensearch_role.all_org_members_logs
  ]
}

