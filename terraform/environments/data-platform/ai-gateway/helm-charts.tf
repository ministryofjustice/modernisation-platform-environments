resource "helm_release" "ai_gateway_configuration" {
  name      = "${local.component_name}-configuration"
  chart     = "${path.module}/src/helm/charts/${local.component_name}-configuration"
  version   = "1.4.1"
  namespace = module.ai_gateway_namespace.name

  values = [
    templatefile(
      "${path.module}/src/helm/values/${local.component_name}-configuration/values.yml.tftpl",
      {
        hostname        = local.environment_configuration.ai_gateway_hostname
        admin_hostname  = "admin.${local.environment_configuration.ai_gateway_hostname}"
        certificate_arn = module.acm_ai_gateway.acm_certificate_arn
        alb_logs_bucket = module.alb_access_logs.s3_bucket_id
      }
    )
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

        # AWS
        iamRole = module.iam_role.arn

        # Autoscaling
        minReplicas                    = local.environment_configuration.ai_gateway_autoscaling.min_replicas
        maxReplicas                    = local.environment_configuration.ai_gateway_autoscaling.max_replicas
        targetCPUUtilizationPercentage = local.environment_configuration.ai_gateway_autoscaling.target_cpu_utilization_percentage

        # LiteLLM Models
        bedrockModels = try(local.environment_configuration.ai_gateway_models.bedrock, {})

        # Admin
        proxyAdminEmail = join(", ", local.environment_configurations.proxy_admin_emails)
      }
    )
  ]

  depends_on = [
    helm_release.litellm_admin,
    module.iam_role,
    kubernetes_service_account_v1.ai_gateway,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_salt_key,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache,
    null_resource.cleanup_psql_temp
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

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "elasticache"
        ]

        # AWS
        iamRole = module.iam_role.arn

        # LiteLLM Models
        bedrockModels = try(local.environment_configuration.ai_gateway_models.bedrock, {})

        # Audit Logs
        auditLogsBucket = module.audit_logs.s3_bucket_id
        auditLogsRegion = data.aws_region.current.region

        # Admin
        proxyAdminEmail = join(", ", local.environment_configurations.proxy_admin_emails)
      }
    )
  ]

  depends_on = [
    module.ai_gateway_aurora,
    module.iam_role,
    kubernetes_service_account_v1.ai_gateway,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_salt_key,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache,
    null_resource.cleanup_psql_temp
  ]
}
