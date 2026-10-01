locals {

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  common_tags = merge(
    var.tags,
    {
      ManagedBy   = "Terraform"
      Region      = local.region
      AccountId   = local.account_id
      AccountName = terraform.workspace
    }
  )

  # Need wildcard glue table ARN to allow access to all tables in the database.
  # Since avature want to handle their own tables.
  # As we're creating the glue database with a module, we need to be able to create the wildcard arn for all tables.
  # https://docs.aws.amazon.com/glue/latest/dg/glue-specifying-resource-arns.html
  glue_table_arn = "${replace(
    var.glue_database_arn,
    ":database/",
    ":table/"
  )}/${var.glue_table_name}"
}

