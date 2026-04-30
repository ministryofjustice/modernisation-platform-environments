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
        databaseSecret      = "rds"
        databaseUserNameKey = "username"
        databasePasswordKey = "password"
        databaseEndpointKey = "host"
        databaseName        = module.ai_gateway_rds.db_instance_name

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "justiceai-azure-openai",
          "azure-openai"
        ]

        # AWS
        iamRole = module.iam_role.arn

        # Autoscaling
        minReplicas                    = local.environment_configuration.ai_gateway_autoscaling.min_replicas
        maxReplicas                    = local.environment_configuration.ai_gateway_autoscaling.max_replicas
        targetCPUUtilizationPercentage = local.environment_configuration.ai_gateway_autoscaling.target_cpu_utilization_percentage

        # LiteLLM Models
        azureModels   = try(local.environment_configuration.ai_gateway_models.azure, {})
        bedrockModels = try(local.environment_configuration.ai_gateway_models.bedrock, {})
      }
    )
  ]

  depends_on = [
    module.iam_role,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_justiceai_azure_openai,
    kubernetes_manifest.external_secret_azure_openai,
    kubernetes_manifest.external_secret_rds
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
        databaseSecret      = "rds"
        databaseUserNameKey = "username"
        databasePasswordKey = "password"
        databaseEndpointKey = "host"
        databaseName        = module.ai_gateway_rds.db_instance_name

        # LiteLLM
        masterkeySecretName = kubernetes_secret_v1.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
        ]
      }
    )
  ]

  depends_on = [
    helm_release.litellm,
    kubernetes_secret_v1.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_rds
  ]
}
