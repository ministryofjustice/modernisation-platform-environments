data "aws_ssoadmin_instances" "main" {}

data "aws_identitystore_group" "this" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = var.identity_centre_team
  }
}
