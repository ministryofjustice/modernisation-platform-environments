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

module "transfer_web_app_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.0"

  name        = "${local.application_name}-transfer-web-app-policy"
  description = "AWS Transfer web app access grants policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_web_app.json
}

module "transfer_web_app_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  create          = true
  use_name_prefix = false
  name            = "transfer_web_app"
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
    transfer_web_app = module.transfer_web_app_policy.arn
  }
}

resource "aws_transfer_web_app" "this" {
  endpoint_details {
    vpc {
      security_group_ids = [aws_security_group.transfer.id]
      subnet_ids         = module.isolated_vpc.public_subnets
      vpc_id             = module.isolated_vpc.vpc_id
    }
  }
  identity_provider_details {
    identity_center_config {
      instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
      role         = aws_iam_role.example.arn
    }
  }
  web_app_units {
    provisioned = 1
  }
}