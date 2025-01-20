module "airflow_requirements_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.4.0"

  bucket        = module.mwaa_bucket.s3_bucket_id
  key           = "requirements.txt"
  file_source   = "src/airflow/requirements.txt"
  force_destroy = true

  tags = local.tags
}

module "airflow_kube_config_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.4.0"

  bucket = module.mwaa_bucket.s3_bucket_id
  key    = ".kube/config"
  content = templatefile("${path.module}/src/airflow/kube_config", {
    cluster_name           = module.eks.cluster_name
    cluster_server         = module.eks.cluster_endpoint
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  })
  force_destroy = true

  tags = local.tags
}
