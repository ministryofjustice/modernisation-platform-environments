terraform{

    required_version = ">=1.7.0"
}


# ------------------------------------------------------------------------------
# Create the AWS Glue database
# ------------------------------------------------------------------------------


module "glue_catalog_database" {
  source = "source = "git::https://github.com/ministryofjustice/modernisation-platform-environments.git//terraform/environments/data-factory-corporate/corporate_data/modules/glue_catalog?ref=abc1234567890abc1234567890abc1234567890a"

  catalog_database_name        = "analytics"
  catalog_database_description = "Glue Catalog database using data located in an S3 bucket"
  location_uri                 = "s3://${module.s3_bucket_source.bucket_id}"

  context = module.this.context
}