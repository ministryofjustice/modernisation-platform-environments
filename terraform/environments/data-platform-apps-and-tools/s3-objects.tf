##################################################
# Airflow Kubernetes Config
##################################################

resource "aws_s3_object" "airflow_kubernetes_config" {
  bucket = module.airflow_s3_bucket.bucket.id
  content = templatefile("${path.module}/src/airflow/kubernetes-config.tmpl", {
    certificate_authority_data = local.environment_configuration.eks_certificate_authority_data
    server                     = local.environment_configuration.eks_server
    cluster_name               = local.environment_configuration.eks_cluster_name
  })
  key = "dags/.kube/config"
}

##################################################
# Airflow Requirements
##################################################

resource "aws_s3_object" "airflow_requirements" {
  bucket      = module.airflow_s3_bucket.bucket.id
  source      = "${path.module}/src/airflow/requirements.txt"
  key         = local.airflow_requirements_s3_path
  source_hash = filemd5("${path.module}/src/airflow/requirements.txt")
}
