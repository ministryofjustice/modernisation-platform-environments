###############################################################################
# Nexthink AWS WorkSpaces inbound connector
# https://docs.nexthink.com/configuring_nexthink/bringing-data-into-your-nexthink-instance/integrating-nexthink-with-third-party-tools/inbound-connectors/connector-for-aws-workspaces
###############################################################################

locals {
  nexthink_aws_account_id = "884848470805"
  nexthink_external_id    = try(local.application_data.accounts[local.environment].nexthink_external_id, "")
  deploy_nexthink         = local.deploy_workspaces && local.nexthink_external_id != ""
}

data "aws_iam_policy_document" "nexthink_assume_role" {
  count = local.deploy_nexthink ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.nexthink_aws_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.nexthink_external_id]
    }
  }
}

data "aws_iam_policy_document" "nexthink_workspaces_read" {
  #checkov:skip=CKV_AWS_356: WorkSpaces Describe* actions do not support resource-level constraints
  #checkov:skip=CKV_AWS_111: Read-only Describe* actions; no write access granted
  count = local.deploy_nexthink ? 1 : 0

  statement {
    sid    = "DescribeWorkspacesInfo"
    effect = "Allow"
    actions = [
      "workspaces:DescribeWorkspaceImages",
      "workspaces:DescribeWorkspacesPoolSessions",
      "workspaces:DescribeWorkspacesPools",
      "workspaces:DescribeWorkspaceBundles",
      "workspaces:DescribeWorkspaces",
    ]
    resources = ["*"]
  }
}

# Nexthink requires the role name to start with "NexthinkConnector-"
resource "aws_iam_role" "nexthink_connector" {
  count              = local.deploy_nexthink ? 1 : 0
  name               = "NexthinkConnector-${local.application_name}-workspaces"
  description        = "Assumed by Nexthink to read AWS WorkSpaces inventory for the AWS WorkSpaces inbound connector"
  assume_role_policy = data.aws_iam_policy_document.nexthink_assume_role[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "nexthink_workspaces_read" {
  count  = local.deploy_nexthink ? 1 : 0
  name   = "nexthink-workspaces-read"
  role   = aws_iam_role.nexthink_connector[0].id
  policy = data.aws_iam_policy_document.nexthink_workspaces_read[0].json
}
