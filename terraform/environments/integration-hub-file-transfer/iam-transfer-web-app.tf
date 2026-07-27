data "aws_iam_policy_document" "transfer_web_app" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetDataAccess",
      "s3:ListCallerAccessGrants",
    ]
    resources = ["arn:aws:s3:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:access-grants/*"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "s3:ResourceAccount"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAccessGrantsInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "s3:ResourceAccount"
    }
  }
}

module "iam_policy_transfer_web_app" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name        = "${local.application_name}-transfer-web-app-policy"
  description = "AWS Transfer web app access grants policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_web_app.json
}

module "iam_role_transfer_web_app" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  create          = true
  use_name_prefix = false
  name            = "transfer-web-app"
  description     = "AWS Transfer web app role"

  trust_policy_permissions = {
    AllowTransferWebApp = {
      effect  = "Allow"
      actions = ["sts:AssumeRole", "sts:SetContext"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
      condition = [{
        test     = "StringEquals"
        values   = [data.aws_caller_identity.current.account_id]
        variable = "aws:SourceAccount"
      }]
    }
  }

  policies = {
    transfer_web_app = module.iam_policy_transfer_web_app.arn
  }
}
