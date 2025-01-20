module "airflow_requirements_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.4.0"

  bucket        = module.mwaa_bucket.s3_bucket_id
  key           = "requirements.txt"
  file_source   = "src/airflow/requirements.txt"
  force_destroy = true
}
