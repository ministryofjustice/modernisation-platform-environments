resource "helm_release" "litellm" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  name       = "litellm"
  repository = "oci://ghcr.io/berriai"
  version    = local.environment_configuration.litellm_versions.chart
  chart      = "litellm-helm"
  namespace  = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
  values = [
    templatefile(
      "${path.module}/src/helm/values/litellm/values.yml.tftpl",
      {
        # Kubernetes
        namespace            = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
        ingressIdentifier    = "litellm"
        ingressColour        = "green"
        imageRepository      = "ghcr.io/berriai/litellm-non_root"
        imageTag             = local.environment_configuration.litellm_versions.application
        serviceAccountName   = data.kubernetes_secret.irsa[0].data["serviceaccount"]
        ingressHostname      = local.environment_configuration.llm_gateway_hostname
        ingressTlsSecretName = "llms-gateway-tls" # what an annoying typo on my part
        ingressAllowList     = local.environment_configuration.llm_gateway_ingress_allowlist

        # Database
        databaseSecret      = data.kubernetes_secret.rds[0].metadata[0].name
        databaseUserNameKey = "database_username"
        databasePasswordKey = "database_password"
        databaseEndpointKey = "rds_instance_endpoint"
        databaseName        = data.kubernetes_secret.rds[0].data["database_name"]

        # LiteLLM
        masterkeySecretName = kubernetes_secret.litellm_master_key[0].metadata[0].name
        masterkeySecretKey  = "master-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        environmentSecrets = [
          data.kubernetes_secret.elasticache[0].metadata[0].name,
          kubernetes_secret.litellm_license[0].metadata[0].name,
          kubernetes_secret.litellm_entra_id[0].metadata[0].name,
          kubernetes_secret.justiceai_azure_openai[0].metadata[0].name,
        ]

        # AWS
        iamRole = module.iam_role[0].arn

        # LiteLLM Models
        azureModels   = local.environment_configuration.llm_gateway_models.azure
        bedrockModels = local.environment_configuration.llm_gateway_models.bedrock
      }
    )
  ]

  depends_on = [
    module.iam_role,
    kubernetes_secret.litellm_master_key,
    kubernetes_secret.litellm_license,
    kubernetes_secret.litellm_entra_id
  ]
}
