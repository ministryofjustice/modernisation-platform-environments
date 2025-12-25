module "airflow_requirements_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "5.8.2"

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
  version = "5.8.2"

  bucket = module.mwaa_bucket.s3_bucket_id
  key    = "dags/.kube/config"
  content = templatefile("${path.module}/src/airflow/kube_config", {
    cluster_name                       = data.aws_eks_cluster.apc_cluster.name
    cluster_server                     = data.aws_eks_cluster.apc_cluster.endpoint
    cluster_certificate_authority_data = data.aws_eks_cluster.apc_cluster.certificate_authority[0].data
  })
  force_destroy = true

  tags = local.tags
}

module "airflow_plugins_object" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "5.8.2"

  bucket        = module.mwaa_bucket.s3_bucket_id
  key           = "plugins.zip"
  file_source   = "plugins.zip"
  source_hash   = data.archive_file.airflow_plugins.output_md5
  force_destroy = true

  tags = local.tags
}
