resource "helm_release" "mlflow" {
  /* https://github.com/ministryofjustice/analytical-platform-mlflow */
  name       = "mlflow"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.22.1-rc2"
  chart      = "mlflow"
  namespace  = kubernetes_namespace.mlflow.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/mlflow/values.yml.tftpl",
      {
        mlflow_hostname = "mlflow.${local.environment_configuration.route53_zone}"
        eks_role_arn    = module.mlflow_iam_role.iam_role_arn
        s3_bucket_name  = local.environment_configuration.mlflow_s3_bucket_name
      }
    )
  ]
  depends_on = [
    module.mlflow_iam_role,
    kubernetes_secret.mlflow_admin,
    kubernetes_secret.mlflow_auth_rds,
    kubernetes_secret.mlflow_rds
  ]
}
