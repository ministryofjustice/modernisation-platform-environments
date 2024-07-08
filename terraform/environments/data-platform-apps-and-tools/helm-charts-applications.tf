resource "helm_release" "static_assets" {
  name      = "static-assets"
  chart     = "./src/helm/charts/static-assets"
  namespace = kubernetes_namespace.static_assets.metadata[0].name

  set {
    name  = "ingress.host"
    value = local.environment_configuration.static_assets_hostname
  }

  depends_on = [helm_release.cert_manager_additional]
}

# resource "helm_release" "openmetadata_dependencies" {
#   name       = "openmetadata-dependencies"
#   repository = "https://helm.open-metadata.org"
#   chart      = "openmetadata-dependencies"
#   version    = "1.2.1"
#   namespace  = kubernetes_namespace.openmetadata.metadata[0].name
#   values = [
#     templatefile(
#       "${path.module}/src/helm/openmetadata-dependencies/values.yml.tftpl",
#       {
#         openmetadata_airflow_password                = random_password.openmetadata_airflow.result
#         openmetadata_airflow_eks_role_arn            = module.openmetadata_airflow_iam_role.iam_role_arn
#         openmetadata_airflow_rds_host                = module.openmetadata_airflow_rds.db_instance_address
#         openmetadata_airflow_rds_user                = module.openmetadata_airflow_rds.db_instance_username
#         openmetadata_airflow_rds_db                  = module.openmetadata_airflow_rds.db_instance_name
#         openmetadata_airflow_rds_password_secret     = kubernetes_secret.openmetadata_airflow_rds_credentials.metadata[0].name
#         openmetadata_airflow_rds_password_secret_key = "password"
#         openmetadata_airflow_admin_email             = "${local.environment_configuration.airflow_mail_from_address}@${local.environment_configuration.ses_domain_identity}"
#       }
#     )
#   ]
#   wait    = true
#   timeout = 600

#   depends_on = [kubernetes_secret.openmetadata_airflow]
# }

# resource "helm_release" "openmetadata" {
#   name       = "openmetadata"
#   repository = "https://helm.open-metadata.org"
#   chart      = "openmetadata"
#   version    = "1.2.1"
#   namespace  = kubernetes_namespace.openmetadata.metadata[0].name
#   values = [
#     templatefile(
#       "${path.module}/src/helm/openmetadata/values.yml.tftpl",
#       {
#         host                                 = "catalogue.${local.environment_configuration.route53_zone}"
#         eks_role_arn                         = module.openmetadata_iam_role.iam_role_arn
#         client_id                            = data.aws_secretsmanager_secret_version.openmetadata_entra_id_client_id.secret_string
#         tenant_id                            = data.aws_secretsmanager_secret_version.openmetadata_entra_id_tenant_id.secret_string
#         jwt_key_id                           = random_uuid.openmetadata_jwt.result
#         openmetadata_airflow_username        = "${local.environment_configuration.airflow_mail_from_address}@${local.environment_configuration.ses_domain_identity}"
#         openmetadata_airflow_password_secret = kubernetes_secret.openmetadata_airflow.metadata[0].name
#         #checkov:skip=CKV_SECRET_6:Reference to Kubernetes secret not a sensitive value
#         openmetadata_airflow_password_secret_key    = "openmetadata-airflow-password"
#         openmetadata_opensearch_host                = resource.aws_opensearch_domain.openmetadata.endpoint
#         openmetadata_opensearch_user                = "openmetadata"
#         openmetadata_opensearch_password_secret     = kubernetes_secret.openmetadata_opensearch_credentials.metadata[0].name
#         openmetadata_opensearch_password_secret_key = "password"
#         openmetadata_rds_host                       = module.openmetadata_rds.db_instance_address
#         openmetadata_rds_user                       = module.openmetadata_rds.db_instance_username
#         openmetadata_rds_dbname                     = module.openmetadata_rds.db_instance_name
#         openmetadata_rds_password_secret            = kubernetes_secret.openmetadata_rds_credentials.metadata[0].name
#         openmetadata_rds_password_secret_key        = "password"
#       }
#     )
#   ]
#   wait    = true
#   timeout = 600

#   depends_on = [helm_release.openmetadata_dependencies]
# }
