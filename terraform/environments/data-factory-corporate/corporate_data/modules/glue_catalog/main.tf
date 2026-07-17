# ------------------------------------------------------------------------------
# Create the AWS Glue database
# ------------------------------------------------------------------------------
# A Glue database is like a folder/container inside the AWS Glue Data Catalog.
# It holds one or more Glue tables.
#
# Example:
#   Glue Database: corporate_database
#       ├── table_1
#       ├── table_2
#       └── table_3
#
# This resource creates the Glue database directly using the AWS provider.
# The actual database name and description come from variables, so they can be
# controlled from variables.tf / terraform.tfvars rather than being hardcoded here.
# ------------------------------------------------------------------------------

resource "aws_glue_catalog_database" "corporate_glue_database" {
  # The name of the Glue database that will be created in AWS.
  # This value comes from var.database_name.
  #
  # Example:
  #   database_name = "corporate_database"
  name = var.database_name

  # A human-readable description of the Glue database.
  # This helps other users understand what the database is for.
  #
  # Example:
  #   database_description = "Glue database for corporate S3 datasets"
  description = var.database_description
}


# ------------------------------------------------------------------------------
# Create Glue tables using the Cloud Posse Glue table module
# ------------------------------------------------------------------------------
# This block uses a public reusable Terraform module from Cloud Posse.
#
# Instead of writing the full aws_glue_catalog_table resource ourselves, we call
# Cloud Posse's glue-catalog-table module and pass it the information it needs.
#
# This module will create Glue Catalog tables inside the Glue database above.
#
# The key benefit is that this block is generic:
#   - it loops over var.tables
#   - it creates one Glue table for each entry
#   - table-specific values come from terraform.tfvars
#
# So if var.tables contains 3 tables, this module block creates 3 Glue tables.
# ------------------------------------------------------------------------------

module "corporate_glue_table" {
  # This tells Terraform where to get the reusable module from.
  #
  # Breakdown:
  #   cloudposse = the publisher/organisation
  #   glue      = the Terraform module name
  #   aws       = the provider/platform
  #
  # The double slash // means:
  #   "Use a specific subfolder inside the module."
  #
  # In this case we are using Cloud Posse's Glue Catalog Table submodule.
  source = "cloudposse/glue/aws//modules/glue-catalog-table"

  # Pinning the module version helps make Terraform predictable.
  #
  # Without a version, Terraform may use a newer module version in the future,
  # which could behave differently and unexpectedly change your plan output.
  version = "0.4.0"

  # This loops over every table defined in var.tables.
  #
  # var.tables is expected to be a map, for example:
  #
  # tables = {
  #   table_one = {
  #     s3_location = "s3://bucket/table-one/"
  #     columns     = [...]
  #   }
  #
  #   table_two = {
  #     s3_location = "s3://bucket/table-two/"
  #     columns     = [...]
  #   }
  # }
  #
  # Terraform will create one module instance per table.
  #
  # For example:
  #   module.corporate_glue_table["table_one"]
  #   module.corporate_glue_table["table_two"]
  for_each = var.tables

  # The Glue table name.
  #
  # each.key is the name/key of the current table in var.tables.
  #
  # Example:
  #   tables = {
  #     payroll = { ... }
  #   }
  #
  # Here, each.key would be:
  #   "payroll"
  #
  # So the Glue table would be called payroll.
  catalog_table_name = each.key

  # Optional description for the Glue table.
  #
  # This tries to use each.value.description.
  # If that field is not provided for a table, it uses null instead.
  #
  # In plain English:
  #   "Use the description if one exists; otherwise leave it blank."
  catalog_table_description = try(each.value.description, null)

  # This tells the table which Glue database it belongs to.
  #
  # It references the Glue database created above:
  #
  #   aws_glue_catalog_database.corporate_glue_database.name
  #
  # This means the tables are created inside the same database.
  database_name = aws_glue_catalog_database.corporate_glue_database.name

  # This tells Glue that the table is external.
  #
  # External table means:
  #   - Glue stores the table metadata
  #   - the actual data is stored somewhere else, usually S3
  #
  # Glue is not storing the data itself.
  # It is pointing to files in S3.
  table_type = "EXTERNAL_TABLE"

  # Extra table parameters for Glue.
  #
  # The merge() function combines:
  #   1. a default map containing EXTERNAL = "TRUE"
  #   2. any extra parameters provided for this specific table
  #
  # EXTERNAL = "TRUE" reinforces that this is an external table.
  #
  # try(each.value.parameters, {}) means:
  #   - use extra parameters if they exist
  #   - otherwise use an empty map {}
  #
  # Example extra parameters might be:
  #
  # parameters = {
  #   classification = "parquet"
  # }
  parameters = merge(
    {
      EXTERNAL = "TRUE"
    },
    try(each.value.parameters, {})
  )

  # ---------------------------------------------------------------------------
  # Storage descriptor
  # ---------------------------------------------------------------------------
  # The storage descriptor tells Glue how the underlying data is stored.
  #
  # It answers questions like:
  #   - Where is the data in S3?
  #   - What file format is it?
  #   - What columns does the table have?
  #   - What SerDe should be used to read the files?
  #
  # Think of this as the table's "data-reading instructions".
  # ---------------------------------------------------------------------------

  storage_descriptor = {
    # The S3 location where the actual data files live.
    #
    # Example:
    #   s3_location = "s3://my-bucket/payroll/"
    #
    # Glue does not copy this data.
    # It records this location so Athena/Glue can query files from there.
    location = each.value.s3_location

    # The input format tells Glue/Athena how to read the files.
    #
    # This tries to use a table-specific input_format if provided.
    # If not provided, it defaults to the standard Parquet input format.
    #
    # In plain English:
    #   "Use the custom input format if given; otherwise assume Parquet."
    input_format = try(
      each.value.input_format,
      "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    )

    # The output format tells Glue/Athena how the table data is represented
    # when written or handled through Hive-compatible systems.
    #
    # This tries to use a table-specific output_format if provided.
    # If not provided, it defaults to the standard Parquet output format.
    output_format = try(
      each.value.output_format,
      "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    )

    # The list of columns for this Glue table.
    #
    # This keeps the module generic because column names are not hardcoded here.
    # Instead, each table provides its own columns through var.tables.
    #
    # Example in terraform.tfvars:
    #
    # columns = [
    #   {
    #     name = "case_id"
    #     type = "string"
    #   },
    #   {
    #     name = "created_date"
    #     type = "date"
    #   }
    # ]
    #
    # The actual columns can be different for every table.
    columns = each.value.columns

    # -------------------------------------------------------------------------
    # SerDe information
    # -------------------------------------------------------------------------
    # SerDe means Serializer / Deserializer.
    #
    # In plain English, it is the translator that helps Glue/Athena understand
    # the file format and turn files in S3 into rows and columns.
    #
    # For Parquet files, we use the Parquet SerDe.
    # -------------------------------------------------------------------------

    ser_de_info = {
      # Give the SerDe the same name as the table.
      #
      # This is mainly a label.
      name = each.key

      # The SerDe library tells AWS how to interpret the data files.
      #
      # This tries to use a table-specific serialization_library if provided.
      # If not provided, it defaults to the standard Parquet SerDe.
      #
      # In plain English:
      #   "Use this Parquet translator unless the table says otherwise."
      serialization_library = try(
        each.value.serialization_library,
        "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      )

      # Extra SerDe parameters.
      #
      # This tries to use table-specific serde_parameters if provided.
      # If not provided, it uses a simple default:
      #
      #   "serialization.format" = "1"
      #
      # This is a common metadata setting used in Hive-style table definitions.
      parameters = try(each.value.serde_parameters, {
        "serialization.format" = "1"
      })
    }
  }

  # ---------------------------------------------------------------------------
  # Partition keys
  # ---------------------------------------------------------------------------
  # Partition keys describe how the S3 data is split into folders.
  #
  # Example S3 layout:
  #
  #   s3://my-bucket/payroll/year=2026/month=07/
  #
  # In that case, the partition keys might be:
  #   - year
  #   - month
  #
  # Partitioning can make queries faster and cheaper because Athena can scan
  # only the relevant folders instead of all the data.
  #
  # try(each.value.partition_keys, []) means:
  #   - use partition_keys if this table has them
  #   - otherwise use an empty list []
  #
  # So partitioning is optional per table.
  # ---------------------------------------------------------------------------

  partition_keys = try(each.value.partition_keys, [])
}

