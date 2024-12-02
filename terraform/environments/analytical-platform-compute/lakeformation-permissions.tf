resource "aws_lakeformation_lf_tag" "source" {
  count  = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0
  key    = "source"
  values = ["create-a-derived-table"]
}

resource "aws_lakeformation_permissions" "cadet_all_data" {
  for_each = (terraform.workspace == "analytical-platform-compute-production" ?
  toset(["TABLE", "DATABASE"]) : toset([]))

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
