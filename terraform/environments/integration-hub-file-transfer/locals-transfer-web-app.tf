data "aws_identitystore_group" "this" {
  for_each          = toset(local.transfer_iam_identity_center_groups)
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "integration-hub"
    }
  }
}

data "aws_ssoadmin_instances" "this" {
  provider = aws.sso-readonly
}

locals {
  transfer_iam_identity_center_groups = toset([
    "integration-hub"
  ])
}