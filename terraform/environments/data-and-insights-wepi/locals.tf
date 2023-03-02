#### This file can be used to store locals specific to the member account ####

locals {

  # List of AWS-managed IAM policies required by Glue
  glue_iam_policy_list = [
    "AmazonS3FullAccess",
    "AWSGlueServiceRole",
    "AmazonRedshiftFullAccess",
    "AWSGlueSchemaRegistryFullAccess"
  ]
}
