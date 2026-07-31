data "aws_ssoadmin_instances" "this" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  for_each          = local.transfer_iam_identity_center_groups
  provider          = aws.sso-readonly
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  group_id          = each.value.identity_center_group_id
}

locals {
  transfer_web_app_configuration = jsondecode(file("${path.module}/configuration/${local.environment}/transfer-web-app-groups.json"))

  transfer_iam_identity_center_groups = {
    for group_name, group in local.transfer_web_app_configuration.groups : group_name => group
    if group.enabled
  }

  transfer_web_app_group_grants = {
    for grant in flatten([
      for group_name, group in local.transfer_iam_identity_center_groups : [
        for prefix in distinct(concat(["group/${group_name}"], group.additional_prefixes)) : {
          group_name = group_name
          prefix     = prefix
        }
      ]
    ]) : "${grant.group_name}:${grant.prefix}" => grant
  }
}