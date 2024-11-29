resource "aws_lakeformation_permissions" "cadet_all_data" {
  for_each = toset(["TABLE", "DATABASE"])

  principal   = module.copy_apdp_cadet_metadata_to_compute_assumable_role.iam_role_arn
  permissions = ["ALL"] # https://docs.aws.amazon.com/lake-formation/latest/dg/lf-permissions-reference.html

  lf_tag_policy {
    resource_type = each.value
    expression {
      key    = "source"
      values = ["create-a-derived-table"]
    }
  }
}
