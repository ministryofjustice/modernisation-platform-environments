locals {
  access_grants_instance_arn = "arn:aws:s3:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:access-grants/default"
  pickup_grants = merge({}, [for id, recipient in local.recipients : {
    for group in recipient.groups : "${id}/${group}" => {
      recipient_id = id
      group_id     = module.pickup_configuration.assigned_groups[group]
    }
  }]...)
}

# The root state already owns the IAM Identity Center application and Access Grants
# instance. This child registers only its own pickup location and read-only grants.
module "iam_role_pickup_access_grants" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source          = "terraform-aws-modules/iam/aws//modules/iam-role"
  version         = "6.8.2"
  create          = length(local.recipients) > 0
  name            = "${local.pattern_name}-reader"
  use_name_prefix = false
  description     = "Read-only pickup location for the existing Transfer web app"
  trust_policy_permissions = {
    AllowAccessGrants = {
      effect     = "Allow"
      actions    = ["sts:AssumeRole", "sts:SetContext", "sts:SetSourceIdentity"]
      principals = [{ type = "Service", identifiers = ["access-grants.s3.amazonaws.com"] }]
      condition = [
        { test = "StringEquals", variable = "aws:SourceAccount", values = [data.aws_caller_identity.current.account_id] },
        { test = "ArnEquals", variable = "aws:SourceArn", values = [local.access_grants_instance_arn] }
      ]
    }
  }
  policies = { pickup_read = module.iam_policy_pickup_access_grants.arn }
  tags     = local.tags
}

module "iam_policy_pickup_access_grants" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "6.8.2"
  create_policy = length(local.recipients) > 0
  name          = "${local.pattern_name}-reader"
  description   = "Read retained files using identity-scoped S3 Access Grants"
  policy        = data.aws_iam_policy_document.pickup_access.json
  tags          = local.tags
}

data "aws_iam_policy_document" "pickup_access" {
  statement {
    sid       = "ListPickup"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_pickup.s3_bucket_arn]
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = [local.access_grants_instance_arn]
    }
  }
  statement {
    sid       = "ReadPickup"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetObjectTagging"]
    resources = ["${module.s3_pickup.s3_bucket_arn}/*"]
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = [local.access_grants_instance_arn]
    }
  }
  statement {
    sid       = "DecryptPickupThroughS3"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [module.kms_notifications_pipeline.key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_s3control_access_grants_location" "pickup" {
  count          = length(local.recipients) > 0 ? 1 : 0
  iam_role_arn   = module.iam_role_pickup_access_grants.arn
  location_scope = "s3://${module.s3_pickup.s3_bucket_id}"
}

resource "aws_s3control_access_grant" "pickup" {
  for_each                  = local.pickup_grants
  access_grants_location_id = aws_s3control_access_grants_location.pickup[0].access_grants_location_id
  permission                = "READ"
  access_grants_location_configuration {
    s3_sub_prefix = "${each.value.recipient_id}/*"
  }
  grantee {
    grantee_type       = "DIRECTORY_GROUP"
    grantee_identifier = each.value.group_id
  }
}
