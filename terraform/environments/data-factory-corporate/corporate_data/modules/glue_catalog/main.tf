# ------------------------------------------------------------------------------
# Create the AWS Glue database
# ------------------------------------------------------------------------------


module "glue_catalog_database" {
  # Use the Glue catalog database submodule from Cloud Posse.
  source = "cloudposse/glue/aws//modules/glue-catalog-database"

  # Pin the module to a specific version for consistent deployments.
  version = "0.4.0"

  # Set the name of the Glue Data Catalog database.
  catalog_database_name = "analytics"

  # Describe the purpose of the Glue database.
  catalog_database_description = "Glue Catalog database using data located in an S3 bucket"

  # Point the database to the source S3 bucket.
  location_uri = "s3://${module.s3_bucket_source.bucket_id}"

  # Apply the shared Cloud Posse naming, tagging, and environment context.
  context = module.this.context
}