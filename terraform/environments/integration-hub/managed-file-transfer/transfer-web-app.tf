data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "integration_hub" {
  provider          = aws.sso-readonly
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  group_id          = "8662e2b4-3021-7017-56ba-8794aa2047cd" # "integration-hub" group ID in AWS SSO Identity Store
}

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
    transfer_web_app = module.transfer_web_app_policy.arn
  }
}

resource "aws_transfer_web_app" "this" {
  identity_provider_details {
    identity_center_config {
      instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
      role         = module.transfer_web_app_role.arn
    }
  }
  web_app_units {
    provisioned = 1
  }
}

resource "aws_s3control_access_grants_instance" "this" {
  identity_center_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

data "aws_iam_policy_document" "s3_access_grants_location" {
  statement {
    sid    = "AllowUnscannedObjectWrites"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3_bucket["unscanned"].s3_bucket_arn}/*",
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
    sid    = "AllowUnscannedKMSWrites"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    resources = [
      module.kms_s3_bucket["unscanned"].key_arn,
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

module "s3_access_grants_location_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.0"

  name        = "${local.application_name}-s3-access-grants-location-policy"
  description = "AWS S3 Access Grants write access to the unscanned bucket"
  path        = "/"

  policy = data.aws_iam_policy_document.s3_access_grants_location.json
}

module "s3_access_grants_location_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "transfer-s3-access-grants-location"
  use_name_prefix = false
  description     = "Role to allow AWS S3 Access Grants to write to the unscanned bucket"

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
    unscanned_access = module.s3_access_grants_location_policy.arn
  }
}

resource "aws_s3control_access_grants_location" "unscanned" {
  depends_on = [aws_s3control_access_grants_instance.this]

  iam_role_arn   = module.s3_access_grants_location_role.arn
  location_scope = "s3://${module.s3_bucket["unscanned"].s3_bucket_id}"
}

resource "aws_s3control_access_grant" "unscanned_uploaders" {
  access_grants_location_id = aws_s3control_access_grants_location.unscanned.access_grants_location_id
  permission                = "WRITE"

  access_grants_location_configuration {
    s3_sub_prefix = "*"
  }

  grantee {
    grantee_type       = "DIRECTORY_GROUP"
    grantee_identifier = data.aws_identitystore_group.integration_hub.group_id
  }
}
