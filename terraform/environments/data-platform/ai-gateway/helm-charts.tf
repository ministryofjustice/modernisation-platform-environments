resource "helm_release" "ai_gateway_configuration" {
  name      = "${local.component_name}-configuration"
  chart     = "${path.module}/src/helm/charts/${local.component_name}-configuration"
  version   = "1.6.0"
  namespace = module.ai_gateway_namespace.name

  values = [
    templatefile(
      "${path.module}/src/helm/values/${local.component_name}-configuration/values.yml.tftpl",
      {
        hostname          = local.environment_configuration.ai_gateway_hostname
        admin_hostname    = "admin.${local.environment_configuration.ai_gateway_hostname}"
        internal_hostname = "internal.${local.environment_configuration.ai_gateway_hostname}"
        certificate_arn   = module.acm_ai_gateway.acm_certificate_arn
        alb_logs_bucket   = module.alb_access_logs.s3_bucket_id
        # Default is 60s; large file uploads (e.g. audio transcription) can take longer to process.
        idle_timeout_seconds = try(local.environment_configuration.ai_gateway_alb_idle_timeout_seconds, 300)
      }
    )
  ]
}

resource "helm_release" "litellm_admin" {
  name       = "litellm-admin"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_version
  chart      = "litellm-helm"
  namespace  = local.component_name
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm-admin/values.yml.tftpl",
      {
        # Kubernetes
        namespace          = local.component_name
        imageRepository    = "ghcr.io/berriai/litellm-non_root"
        imageTag           = local.environment_configuration.litellm_version
        serviceAccountName = kubernetes_service_account_v1.ai_gateway.metadata[0].name
        ingressHostname    = "admin.${local.environment_configuration.ai_gateway_hostname}"
        proxyHostname      = local.environment_configuration.ai_gateway_hostname

        # Database
        databaseSecret            = "aurora"
        databaseUserNameKey       = "username"
        databasePasswordKey       = "password"
        databaseEndpointKey       = "host"
        databaseReaderEndpointKey = local.has_reader ? "read-url" : ""
        databaseName              = module.ai_gateway_aurora.cluster_database_name
        databaseUsername          = module.ai_gateway_aurora.cluster_master_username

        # Azure
        microsoft_foundry_tenant_id = jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["tenant_id"]
        microsoft_foundry_client_id = jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["client_id"]

        # Google
        googleWorkloadIdentityAudience        = local.google_workload_identity_audience
        googleApplicationCredentialsConfigMap = kubernetes_config_map_v1.google_application_credentials.metadata[0].name

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "elasticache"
        ]

        # Audit Logs
        auditLogsBucket = module.audit_logs.s3_bucket_id
        auditLogsRegion = data.aws_region.current.region

        # Admin
        proxyAdminEmail = join(", ", local.proxy_admin_emails)
      }
    )
  ]

  timeout = 700

  depends_on = [
    module.ai_gateway_aurora,
    module.iam_role,
    kubernetes_service_account_v1.ai_gateway,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_config_map_v1.google_application_credentials,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_salt_key,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache,
    kubernetes_job_v1.grant_rds_iam
  ]
}

resource "helm_release" "litellm" {
  name       = "litellm"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_version
  chart      = "litellm-helm"
  namespace  = local.component_name
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm/values.yml.tftpl",
      {
        # Kubernetes
        namespace          = local.component_name
        imageRepository    = "ghcr.io/berriai/litellm-non_root"
        imageTag           = local.environment_configuration.litellm_version
        serviceAccountName = kubernetes_service_account_v1.ai_gateway.metadata[0].name
        ingressHostname    = local.environment_configuration.ai_gateway_hostname

        # Database
        databaseSecret            = "aurora"
        databaseUserNameKey       = "username"
        databasePasswordKey       = "password"
        databaseEndpointKey       = "host"
        databaseReaderEndpointKey = local.has_reader ? "read-url" : ""
        databaseName              = module.ai_gateway_aurora.cluster_database_name
        databaseUsername          = module.ai_gateway_aurora.cluster_master_username

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "elasticache"
        ]

        # Azure
        microsoft_foundry_tenant_id = jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["tenant_id"]
        microsoft_foundry_client_id = jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["client_id"]

        # Google
        googleWorkloadIdentityAudience        = local.google_workload_identity_audience
        googleApplicationCredentialsConfigMap = kubernetes_config_map_v1.google_application_credentials.metadata[0].name

        # Autoscaling
        minReplicas                    = local.environment_configuration.ai_gateway_autoscaling.min_replicas
        maxReplicas                    = local.environment_configuration.ai_gateway_autoscaling.max_replicas
        targetCPUUtilizationPercentage = local.environment_configuration.ai_gateway_autoscaling.target_cpu_utilization_percentage

        # LiteLLM models are stored in the database; no model list is templated here.
        # Admin
        proxyAdminEmail = join(", ", local.proxy_admin_emails)

        # How often (in seconds) LiteLLM checks each model's health.
        # Comes from the environment config; defaults to 300s if not set.
        # Note: if you change this, also check the alert's rate() window
        # still has enough samples to work correctly.
        ai_background_health_check_interval = try(local.environment_configuration.ai_background_health_check_interval, 300)
      }
    )
  ]

  timeout = 700

  depends_on = [
    helm_release.litellm_admin,
    module.iam_role,
    kubernetes_service_account_v1.ai_gateway,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_config_map_v1.google_application_credentials,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_salt_key,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache,
    kubernetes_job_v1.grant_rds_iam
  ]
}
