resource "helm_release" "ai_gateway_configuration" {
  name      = "ai-gateway-configuration"
  chart     = "${path.module}/src/helm/charts/ai-gateway-configuration"
  version   = "1.4.0"
  namespace = "ai-gateway"

  values = [
    templatefile(
      "${path.module}/src/helm/values/ai-gateway-configuration/values.yml.tftpl",
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
  version    = local.environment_configuration.litellm_versions.chart
  chart      = "litellm-helm"
  namespace  = "ai-gateway"
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm/values.yml.tftpl",
      {
        # Kubernetes
        namespace          = "ai-gateway"
        imageRepository    = "ghcr.io/berriai/litellm-non_root"
        imageTag           = local.environment_configuration.litellm_versions.application
        serviceAccountName = "litellm"
        ingressHostname    = local.environment_configuration.ai_gateway_hostname

        # Database
        databaseSecret      = "aurora"
        databaseUserNameKey = "username"
        databasePasswordKey = "password"
        databaseEndpointKey = "host"
        databaseName        = module.ai_gateway_aurora.cluster_database_name

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
      }
    )
  ]

  depends_on = [
    helm_release.litellm_admin,
    module.iam_role,
    kubernetes_service_account_v1.litellm,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache
  ]
}

resource "helm_release" "litellm_admin" {
  name       = "litellm-admin"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_versions.chart
  chart      = "litellm-helm"
  namespace  = "ai-gateway"
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm-admin/values.yml.tftpl",
      {
        # Kubernetes
        namespace          = "ai-gateway"
        imageRepository    = "ghcr.io/berriai/litellm-non_root"
        imageTag           = local.environment_configuration.litellm_versions.application
        serviceAccountName = "litellm"
        ingressHostname    = "admin.${local.environment_configuration.ai_gateway_hostname}"

        # Database
        databaseSecret      = "aurora"
        databaseUserNameKey = "username"
        databasePasswordKey = "password"
        databaseEndpointKey = "host"
        databaseName        = module.ai_gateway_aurora.cluster_database_name

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "elasticache"
        ]
      }
    )
  ]

  depends_on = [
    module.ai_gateway_aurora,
    kubernetes_service_account_v1.litellm,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_aurora,
    kubernetes_manifest.external_secret_elasticache
  ]
}
