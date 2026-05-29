data "aws_ssoadmin_instances" "main" {}

data "aws_identitystore_groups" "all" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

locals {
  identitystore_group_id = one([
    for group in data.aws_identitystore_groups.all.groups :
    group.group_id if group.display_name == var.identity_centre_team
  ])
}
