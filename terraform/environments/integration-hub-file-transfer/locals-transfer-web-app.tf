data "aws_ssoadmin_instances" "this" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  for_each          = local.transfer_iam_identity_center_groups
  provider          = aws.sso-readonly
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  group_id          = each.value
}

locals {
  # GetGroupId does not reliably resolve groups by display name, so IDs are explicit here.
  transfer_iam_identity_center_groups = {
    integration-hub = "8662e2b4-3021-7017-56ba-8794aa2047cd"
  }
}