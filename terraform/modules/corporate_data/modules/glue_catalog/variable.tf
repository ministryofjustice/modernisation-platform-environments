# ------------------------------------------------------------------------------
# Glue database name
# ------------------------------------------------------------------------------
# This variable stores the name of the AWS Glue database that will be created.
#
# A Glue database is like a container/folder inside the Glue Data Catalog.
# It holds Glue tables.
#
# Example:
#   database_name = "corporate_database"
#
# This value is used in main.tf when creating the Glue database and when telling
# the Glue tables which database they should belong to.
# ------------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the Glue database"
  type        = string
}


# ------------------------------------------------------------------------------
# Glue database description
# ------------------------------------------------------------------------------
# This variable stores a human-readable description for the Glue database.
#
# The description is useful because it helps other people understand what the
# database is for when they look in AWS Glue.
#
# Example:
#   database_description = "Glue database for corporate S3 datasets"
#
# default = null means this value is optional.
# If no description is provided, Terraform will leave it blank.
# ------------------------------------------------------------------------------

variable "database_description" {
  description = "Description of the Glue database"
  type        = string
  default     = null
}


# ------------------------------------------------------------------------------
# Glue tables
# ------------------------------------------------------------------------------
# This variable defines all the Glue tables that should be created.
#
# It is a map, which means each table is listed by name.
#
# Example:
#
# tables = {
#   payroll = {
#     s3_location = "s3://my-bucket/payroll/"
#     columns     = [...]
#   }
#
#   employees = {
#     s3_location = "s3://my-bucket/employees/"
#     columns     = [...]
#   }
# }
#
# In this example:
#   - "payroll" becomes one Glue table
#   - "employees" becomes another Glue table
#
# In main.tf, this is used with:
#
#   for_each = var.tables
#
# That tells Terraform:
#   "Loop through every table in this variable and create a Glue table for each."
# ------------------------------------------------------------------------------

variable "tables" {
  description = "Map of Glue tables to create"

  # ---------------------------------------------------------------------------
  # Type definition
  # ---------------------------------------------------------------------------
  # This tells Terraform what shape the tables variable must have.
  #
  # map(object({...})) means:
  #
  #   map    = a collection of named items
  #   object = each named item must have a defined structure
  #
  # In plain English:
  #   "tables must be a collection of table definitions, and each table
  #    definition must follow the structure below."
  # ---------------------------------------------------------------------------

  type = map(object({

    # -------------------------------------------------------------------------
    # Table description
    # -------------------------------------------------------------------------
    # Optional description for the Glue table.
    #
    # This helps people understand what the table contains.
    #
    # Example:
    #   description = "Payroll data stored in S3"
    #
    # optional(string) means:
    #   - this field can be provided
    #   - but it does not have to be
    # -------------------------------------------------------------------------

    description = optional(string)

    # -------------------------------------------------------------------------
    # S3 location
    # -------------------------------------------------------------------------
    # This is the S3 path where the actual data files live.
    #
    # Example:
    #   s3_location = "s3://my-bucket/payroll/"
    #
    # Glue does not store the real data.
    # Glue stores metadata that points to the data in S3.
    #
    # This field is required because every Glue table must know where its
    # underlying data is stored.
    # -------------------------------------------------------------------------

    s3_location = string

    # -------------------------------------------------------------------------
    # Input format
    # -------------------------------------------------------------------------
    # Optional setting that tells Glue/Athena how to read the files in S3.
    #
    # For Parquet files, the default used in main.tf is usually:
    #
    #   org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat
    #
    # Because this is optional, most tables do not need to provide it if they
    # are using the default Parquet setup.
    #
    # You would only set this if a table needs a different file-reading format.
    # -------------------------------------------------------------------------

    input_format = optional(string)

    # -------------------------------------------------------------------------
    # Output format
    # -------------------------------------------------------------------------
    # Optional setting that tells Glue/Athena how the table data is represented
    # when handled through Hive-compatible systems.
    #
    # For Parquet files, the default used in main.tf is usually:
    #
    #   org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat
    #
    # Because this is optional, most Parquet tables can leave it out.
    # -------------------------------------------------------------------------

    output_format = optional(string)

    # -------------------------------------------------------------------------
    # Serialization library / SerDe
    # -------------------------------------------------------------------------
    # Optional setting that tells Glue/Athena which SerDe library to use.
    #
    # SerDe means Serializer / Deserializer.
    #
    # In plain English:
    #   It is the translator that helps AWS understand the file format and turn
    #   the files in S3 into rows and columns.
    #
    # For Parquet files, the default used in main.tf is usually:
    #
    #   org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe
    #
    # You would only set this if the table needs a different SerDe.
    # -------------------------------------------------------------------------

    serialization_library = optional(string)

    # -------------------------------------------------------------------------
    # Glue table parameters
    # -------------------------------------------------------------------------
    # Optional key-value settings for the Glue table.
    #
    # map(string) means:
    #   - the value should be a map
    #   - every value in the map should be text
    #
    # Example:
    #
    # parameters = {
    #   classification = "parquet"
    # }
    #
    # The default is {}, which means an empty map.
    #
    # In plain English:
    #   "If no extra parameters are provided, use nothing extra."
    # -------------------------------------------------------------------------

    parameters = optional(map(string), {})

    # -------------------------------------------------------------------------
    # SerDe parameters
    # -------------------------------------------------------------------------
    # Optional key-value settings specifically for the SerDe.
    #
    # In main.tf, this can be used inside:
    #
    #   ser_de_info = {
    #     parameters = ...
    #   }
    #
    # Example:
    #
    # serde_parameters = {
    #   "serialization.format" = "1"
    # }
    #
    # This is optional because main.tf already provides a default value.
    # -------------------------------------------------------------------------

    serde_parameters = optional(map(string))

    # -------------------------------------------------------------------------
    # Columns
    # -------------------------------------------------------------------------
    # This is the list of columns that the Glue table should have.
    #
    # Each column must have:
    #   - name
    #   - type
    #
    # A comment is optional.
    #
    # Example:
    #
    # columns = [
    #   {
    #     name    = "case_id"
    #     type    = "string"
    #     comment = "Unique case identifier"
    #   },
    #   {
    #     name = "created_date"
    #     type = "date"
    #   }
    # ]
    #
    # This field is required because a Glue table normally needs a schema,
    # meaning it needs to know what columns exist and what type each column is.
    # -------------------------------------------------------------------------

    columns = list(object({
      # Name of the column as it will appear in Glue/Athena.
      #
      # Example:
      #   name = "case_id"
      name = string

      # Data type of the column.
      #
      # Common Glue/Athena types include:
      #   string
      #   int
      #   bigint
      #   double
      #   boolean
      #   date
      #   timestamp
      #
      # Example:
      #   type = "string"
      type = string

      # Optional description for the column.
      #
      # This helps other users understand what the column means.
      #
      # Example:
      #   comment = "Unique case identifier"
      comment = optional(string)
    }))

    # -------------------------------------------------------------------------
    # Partition keys
    # -------------------------------------------------------------------------
    # Optional list of partition columns.
    #
    # Partition keys describe how the data is split into folders in S3.
    #
    # Example S3 layout:
    #
    #   s3://my-bucket/payroll/year=2026/month=07/
    #
    # In this case, the partition keys might be:
    #   - year
    #   - month
    #
    # Partitioning can help Athena query less data, which can make queries
    # faster and cheaper.
    #
    # This field is optional because not every table is partitioned.
    #
    # The default [] means:
    #   "If no partition keys are provided, use an empty list."
    # -------------------------------------------------------------------------

    partition_keys = optional(list(object({
      # Name of the partition column.
      #
      # Example:
      #   name = "year"
      name = string

      # Data type of the partition column.
      #
      # Partition values are often strings, but this depends on your setup.
      #
      # Example:
      #   type = "string"
      type = string

      # Optional description for the partition column.
      #
      # Example:
      #   comment = "Year partition"
      comment = optional(string)
    })), [])
  }))
}