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
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.0"

  name        = "${local.application_name}-transfer-web-app-policy"
  description = "AWS Transfer web app access grants policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_web_app.json

  tags = local.tags
}

module "iam_role_transfer_web_app" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

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

  tags = local.tags
}

data "aws_iam_policy_document" "s3_access_grants_location" {
  statement {
    sid    = "AllowIncomingBucketReads"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3_bucket["incoming"].s3_bucket_arn,
    ]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:ResourceAccount"
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
      variable = "s3:AccessGrantsInstanceArn"
    }
  }

  statement {
    sid    = "AllowIncomingObjectReads"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts",
    ]
    resources = [
      "${module.s3_bucket["incoming"].s3_bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:ResourceAccount"
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
      variable = "s3:AccessGrantsInstanceArn"
    }
  }

  statement {
    sid    = "AllowIncomingObjectWrites"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3_bucket["incoming"].s3_bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:ResourceAccount"
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
      variable = "s3:AccessGrantsInstanceArn"
    }
  }

  statement {
    sid    = "AllowIncomingKMSAccess"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    resources = [
      module.kms_s3_bucket["incoming"].key_arn,
    ]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "kms:CallerAccount"
    }

    condition {
      test     = "StringEquals"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }
}

module "iam_policy_s3_access_grants_location" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.0"

  name        = "${local.application_name}-s3-access-grants-location-policy"
  description = "AWS S3 Access Grants read/write access to the incoming bucket"
  path        = "/"

  policy = data.aws_iam_policy_document.s3_access_grants_location.json

  tags = local.tags
}

module "iam_role_s3_access_grants_location" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  name            = "transfer-s3-access-grants-location"
  use_name_prefix = false
  description     = "Role to allow AWS S3 Access Grants to read and write to the incoming bucket"

  trust_policy_permissions = {
    AllowAccessGrants = {
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
        "sts:SetContext",
        "sts:SetSourceIdentity",
      ]

      principals = [{
        type        = "Service"
        identifiers = ["access-grants.s3.amazonaws.com"]
      }]

      condition = [
        {
          test     = "StringEquals"
          values   = [data.aws_caller_identity.current.account_id]
          variable = "aws:SourceAccount"
        },
        {
          test     = "ArnEquals"
          values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
          variable = "aws:SourceArn"
        }
      ]
    }
  }

  policies = {
    incoming_access = module.iam_policy_s3_access_grants_location.arn
  }

  tags = local.tags
}
