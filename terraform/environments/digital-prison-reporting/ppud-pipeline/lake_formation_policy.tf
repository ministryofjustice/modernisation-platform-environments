data "aws_iam_policy_document" "lake_formation_data_access" {
  statement {
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lake_formation_data_access" {
  count = (local.is-development || local.is-preproduction) ? 1 : 0

  name        = "${local.project}-${local.short_name}-lake-formation-data-access-${local.environment}"
  description = "Lake Formation GetDataAccess policy"
  policy      = data.aws_iam_policy_document.lake_formation_data_access.json
}
