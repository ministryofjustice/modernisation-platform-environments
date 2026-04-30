resource "helm_release" "litellm" {
  name       = "litellm"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_versions.chart
  chart      = "litellm-helm"
  namespace  = "llm-gateway"
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm/values.yml.tftpl",
      {
        # Kubernetes
        namespace          = "llm-gateway"
        imageRepository    = "ghcr.io/berriai/litellm-non_root"
        imageTag           = local.environment_configuration.litellm_versions.application
        serviceAccountName = "litellm"
        ingressHostname    = local.environment_configuration.llm_gateway_hostname

        # Database
        databaseSecret      = "rds"
        databaseUserNameKey = "username"
        databasePasswordKey = "password"
        databaseEndpointKey = "host"
        databaseName        = module.llm_gateway_rds.db_instance_name

        # LiteLLM
        masterkeySecretName = kubernetes_secret.litellm_master_key.metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          "litellm-license",
          "litellm-entra-id",
          "justiceai-azure-openai",
          "azure-openai"
        ]

        # AWS
        iamRole = module.iam_role.arn

        # LiteLLM Models
        azureModels   = try(local.environment_configuration.llm_gateway_models.azure, {})
        bedrockModels = try(local.environment_configuration.llm_gateway_models.bedrock, {})
      }
    )
  ]

  depends_on = [
    module.iam_role,
    kubernetes_secret.litellm_master_key,
    kubernetes_manifest.external_secret_litellm_license,
    kubernetes_manifest.external_secret_litellm_entra_id,
    kubernetes_manifest.external_secret_justiceai_azure_openai,
    kubernetes_manifest.external_secret_azure_openai,
    kubernetes_manifest.external_secret_rds
  ]
}

resource "helm_release" "litellm_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = helm.cloud_platform

  name       = "litellm"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_versions.chart
  chart      = "litellm-helm"
  namespace  = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm/values-cloud-platform.yml.tftpl",
      {
        # Kubernetes
        namespace            = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
        ingressIdentifier    = "litellm"
        ingressColour        = "green"
        imageRepository      = "ghcr.io/berriai/litellm-non_root"
        imageTag             = local.environment_configuration.litellm_versions.application
        serviceAccountName   = data.kubernetes_secret.irsa[0].data["serviceaccount"]
        ingressHostname      = local.environment_configuration.cloud_platform_hostname
        ingressTlsSecretName = "llms-gateway-tls"
        ingressAllowList     = local.environment_configuration.llm_gateway_ingress_allowlist

        # Database
        databaseSecret      = data.kubernetes_secret.rds[0].metadata[0].name
        databaseUserNameKey = "database_username"
        databasePasswordKey = "database_password"
        databaseEndpointKey = "rds_instance_endpoint"
        databaseName        = data.kubernetes_secret.rds[0].data["database_name"]

        # LiteLLM
        masterkeySecretName = kubernetes_secret.litellm_master_key_cloud_platform[0].metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          data.kubernetes_secret.elasticache[0].metadata[0].name,
          kubernetes_secret.litellm_license_cloud_platform[0].metadata[0].name,
          kubernetes_secret.litellm_entra_id_cloud_platform[0].metadata[0].name,
          kubernetes_secret.justiceai_azure_openai_cloud_platform[0].metadata[0].name,
          kubernetes_secret.azure_openai_cloud_platform[0].metadata[0].name
        ]

        # AWS
        iamRole = module.iam_role_cloud_platform[0].arn

        # LiteLLM Models
        azureModels   = local.environment_configuration.llm_gateway_models.azure
        bedrockModels = local.environment_configuration.llm_gateway_models.bedrock
      }
    )
  ]

  depends_on = [
    module.iam_role_cloud_platform,
    kubernetes_secret.litellm_master_key_cloud_platform,
    kubernetes_secret.litellm_license_cloud_platform,
    kubernetes_secret.litellm_entra_id_cloud_platform
  ]
}
