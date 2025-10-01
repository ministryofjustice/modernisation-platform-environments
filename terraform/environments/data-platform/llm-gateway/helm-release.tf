# resource "helm_release" "litellm" {
#   name       = "litellm"
#   repository = "oci://ghcr.io/berriai"
#   version    = "0.1.785"
#   chart      = "litellm-helm"
#   namespace  = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
#   values = [
#     templatefile(
#       "${path.module}/src/helm/values/litellm/values.yml.tftpl",
#       {
#         imageTag           = "v1.77.3-stable"
#         serviceAccountName = data.kubernetes_secret.irsa[0].data["serviceaccount"]
#         dbUrl              = data.kubernetes_secret.rds[0].data["url"]
#       }
#     )
#   ]
#   # depends_on = [
#   #   module.mlflow_iam_role,
#   #   kubernetes_secret.mlflow_admin,
#   #   kubernetes_secret.mlflow_auth_rds,
#   #   kubernetes_secret.mlflow_rds
#   # ]
# }
