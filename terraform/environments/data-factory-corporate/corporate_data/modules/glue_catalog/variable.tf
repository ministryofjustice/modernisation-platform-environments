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

