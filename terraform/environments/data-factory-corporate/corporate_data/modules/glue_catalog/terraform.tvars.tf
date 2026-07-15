
# ------------------------------------------------------------------------------
# terraform.tfvars
# ------------------------------------------------------------------------------
# This file is where you provide the actual values that Terraform will use.
#
# variables.tf defines the shape of the inputs.
# terraform.tfvars provides the real values for those inputs.
#
# In this example, we are telling Terraform:
#   - what Glue database to create
#   - what description to give it
#   - what Glue tables to create
#   - where each table's data lives in S3
#   - what columns each table should have
#   - whether any table uses partition keys
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Glue database name
# ------------------------------------------------------------------------------
# This is the actual name of the Glue database that will be created in AWS.
#
# In main.tf, this value is used by:
#
#   var.database_name
#
# Example result in AWS Glue:
#
#   Glue database name: corporate_database
# ------------------------------------------------------------------------------

database_name = "corporate_database"


# ------------------------------------------------------------------------------
# Glue database description
# ------------------------------------------------------------------------------
# This is a human-readable description for the Glue database.
#
# It helps other people understand what the Glue database is for when they look
# in the AWS Glue Console.
#
# In main.tf, this value is used by:
#
#   var.database_description
# ------------------------------------------------------------------------------

database_description = "Corporate Glue database for S3 datasets"


# ------------------------------------------------------------------------------
# Glue tables
# ------------------------------------------------------------------------------
# This map contains all the Glue tables you want Terraform to create.
#
# Each entry inside this map becomes one Glue table.
#
# For example:
#
#   table_one = { ... }
#
# creates a Glue table called:
#
#   table_one
#
# and:
#
#   table_two = { ... }
#
# creates a Glue table called:
#
#   table_two
#
# In main.tf, Terraform loops over this map using:
#
#   for_each = var.tables
#
# That means:
#
#   "Create one Glue table for every table listed below."
# ------------------------------------------------------------------------------

tables = {

  # ---------------------------------------------------------------------------
  # First Glue table: table_one
  # ---------------------------------------------------------------------------
  # This block defines the settings for a Glue table called table_one.
  #
  # The table name comes from this map key:
  #
  #   table_one
  #
  # In main.tf, that is picked up using:
  #
  #   each.key
  #
  # So each.key = "table_one" for this table.
  # ---------------------------------------------------------------------------

  table_one = {
    # Optional description for this Glue table.
    #
    # This appears in Glue as the table description.
    description = "First table"

    # S3 location where the actual data files for this table live.
    #
    # Glue does not store the actual data.
    # Glue only stores metadata that points to this S3 location.
    #
    # Replace this example with your real S3 path.
    s3_location = "s3://my-bucket/table-one/"

    # -------------------------------------------------------------------------
    # Columns for table_one
    # -------------------------------------------------------------------------
    # This list defines the schema for table_one.
    #
    # Schema means:
    #   - what columns the table has
    #   - what data type each column is
    #
    # These columns should match the data files stored in the S3 location above.
    # -------------------------------------------------------------------------

    columns = [
      {
        # First column in table_one.
        #
        # This is just an example name.
        # Replace it with the real column name from your data.
        name = "column_a"

        # Data type for column_a.
        #
        # string means text.
        type = "string"
      },
      {
        # Second column in table_one.
        #
        # Replace this with the real column name from your data.
        name = "column_b"

        # Data type for column_b.
        #
        # int means whole number.
        type = "int"
      }
    ]
  }


  # ---------------------------------------------------------------------------
  # Second Glue table: table_two
  # ---------------------------------------------------------------------------
  # This block defines the settings for a Glue table called table_two.
  #
  # This example includes partition keys, which means the S3 data is expected to
  # be organised into partition-style folders.
  # ---------------------------------------------------------------------------

  table_two = {
    # Optional description for this Glue table.
    description = "Second table"

    # S3 location where the actual data files for this table live.
    #
    # Replace this with your real S3 path.
    s3_location = "s3://my-bucket/table-two/"

    # -------------------------------------------------------------------------
    # Columns for table_two
    # -------------------------------------------------------------------------
    # These are the normal data columns in the table.
    #
    # They should match the columns in the underlying S3 data.
    # -------------------------------------------------------------------------

    columns = [
      {
        # First column in table_two.
        name = "another_column"

        # string means text.
        type = "string"
      },
      {
        # Second column in table_two.
        name = "created_date"

        # date means a calendar date, for example 2026-07-14.
        type = "date"
      }
    ]

    # -------------------------------------------------------------------------
    # Partition keys for table_two
    # -------------------------------------------------------------------------
    # Partition keys describe how the data is split into folders in S3.
    #
    # Example S3 layout:
    #
    #   s3://my-bucket/table-two/year=2026/month=07/
    #
    # In that example:
    #   - year is a partition key
    #   - month is a partition key
    #
    # Partitioning helps Athena/Glue scan less data when querying.
    #
    # For example, if you query only year = 2026, Athena can focus on the
    # year=2026 folder instead of scanning every year.
    #
    # This section is optional.
    # If a table is not partitioned, you can leave partition_keys out completely.
    # -------------------------------------------------------------------------

    partition_keys = [
      {
        # First partition key.
        #
        # This should match the folder name in S3, for example:
        #
        #   year=2026
        name = "year"

        # Partition values are often stored as strings.
        type = "string"
      },
      {
        # Second partition key.
        #
        # This should match the folder name in S3, for example:
        #
        #   month=07
        name = "month"

        # Partition values are often stored as strings.
        type = "string"
      }
    ]
  }
}