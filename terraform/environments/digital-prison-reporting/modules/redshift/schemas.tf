# External schema using AWS Glue Data Catalog
resource "redshift_schema" "external_from_glue_data_catalog" {
  count = var.enable_redshift_schema_glue

  name = "domain"
  owner = var.master_username
  external_schema {
    database_name = "domain"
    data_catalog_source {
      region = var.region # Optional. If not specified, Redshift will use the same region as the cluster.
      iam_role_arns = [
        # Required. Must be at least 1 ARN and not more than 10.
        "arn:aws:iam::203591025782:role/dpr-redshift-cluster-role",
      ]
      catalog_role_arns = [
        # Optional. If specified, must be at least 1 ARN and not more than 10.
        # If not specified, Redshift will use iam_role_arns for accessing the glue data catalog.
        "arn:aws:iam::203591025782:role/dpr-redshift-cluster-role",
      ]
      create_external_database_if_not_exists = true # Optional. Defaults to false.
    }
  }
}
