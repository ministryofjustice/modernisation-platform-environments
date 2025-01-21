# Backend
terraform {
  # `backend` blocks do not support variables, so the following are hard-coded here:
  # - S3 bucket name, which is created in modernisation-platform-account/s3.tf
  backend "s3" {
    acl                  = "bucket-owner-full-control"
    bucket               = "modernisation-platform-terraform-state"
    dynamodb_table       = "modernisation-platform-terraform-state-lock"
    encrypt              = true
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    # We'll replace data-platform-apps-and-tools and airflow via sed
    workspace_key_prefix = "environments/members/data-platform-apps-and-tools/airflow"
  }
}
