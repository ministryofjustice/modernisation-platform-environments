/*
##################################################
# Airflow
##################################################

module "airflow_s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "moj-data-platform-airflow-${local.environment}"

  tags = local.tags
}
*/
