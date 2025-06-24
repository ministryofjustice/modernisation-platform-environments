data "aws_iam_policy_document" "cloud_formation_access" {
    statement {
        sid     = "CloudFormationPermissions"
        effect  = "Allow"
        actions = [
          "cloudformation:CreateResource",
          "cloudformation:GetResource",
          "cloudformation:UpdateResource",
          "cloudformation:DeleteResource",
          "cloudformation:ListResources",
          "cloudformation:GetResourceRequestStatus"
        ]
        resources = ["*"]
    }
}

resource "aws_iam_role_policy" "analytical_platform_cloud_formation_policy_attachment" {
  for_each = local.analytical_platform_share

  name   = "${each.value.target_account_name}-cloud-formation-policy"
  role   = aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.cloud_formation_access.json
}
