module "airflow_requirements_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.6.1"

  bucket        = module.mwaa_bucket.s3_bucket_id
  key           = "requirements.txt"
  file_source   = "src/airflow/requirements.txt"
  source_hash   = filemd5("src/airflow/requirements.txt")
  force_destroy = true

  tags = local.tags
}

module "airflow_kube_config_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.6.1"

  bucket = module.mwaa_bucket.s3_bucket_id
  key    = "dags/.kube/config"
  content = templatefile("${path.module}/src/airflow/kube_config", {
    cluster_name                       = module.eks.cluster_name
    cluster_server                     = module.eks.cluster_endpoint
    cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  })
  force_destroy = true

  tags = local.tags
}

module "airflow_plugins_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.6.1"

  bucket        = module.mwaa_bucket.s3_bucket_id
  key           = "plugins.zip"
  file_source   = "plugins.zip"
  source_hash   = data.archive_file.airflow_plugins.output_md5
  force_destroy = true

  tags = local.tags
}
