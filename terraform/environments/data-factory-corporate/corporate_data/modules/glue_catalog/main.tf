terraform{

    required_version = ">=1.7.0"
}


# ------------------------------------------------------------------------------
# Create the AWS Glue database
# ------------------------------------------------------------------------------


module "glue_catalog_database" {
  source = "source = "git::https://github.com/cloudposse/terraform-aws-glue.git//modules/glue-catalog-database?ref=e04ac37bd44efcf29ad0a8fc94149bccc9162a6d"
  version = "0.4.0"
  catalog_database_name        = "corporate_database"
  catalog_database_description = "Glue Catalog database using data located in an S3 bucket"
  location_uri                 = "s3://${module.s3_bucket_source.bucket_id}"

  context = module.this.context
}