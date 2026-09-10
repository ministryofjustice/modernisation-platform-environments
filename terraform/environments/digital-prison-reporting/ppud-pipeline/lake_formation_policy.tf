data "aws_iam_policy_document" "lake_formation_data_access" {
  statement {
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lake_formation_data_access" {
  count = local.is-test ? 0 : 1

  name        = "${local.project}-lake-formation-data-access"
  description = "Lake Formation GetDataAccess policy"
  policy      = data.aws_iam_policy_document.lake_formation_data_access.json
}