module "authenticated_pickup_configuration" {
  source      = "./modules/authenticated-pickup-configuration"
  environment = local.environment
}

locals {
  pickup_recipients = module.authenticated_pickup_configuration.recipients
  pickup_assignments = merge({}, [for recipient_id, recipient in local.pickup_recipients : {
    for principal_id, principal in recipient.principals : "${recipient_id}/${principal_id}" => {
      prefix = recipient.prefix
      type   = principal.type
      id     = principal.id
    }
  }]...)
  pickup_principals = { for assignment in values(local.pickup_assignments) :
    "${assignment.type}/${assignment.id}" => assignment...
  }
}

# A distinct read-only location role prevents pickup grants from inheriting upload access.
resource "aws_s3control_access_grants_location" "clean_pickup" {
  count          = length(local.pickup_recipients) > 0 ? 1 : 0
  depends_on     = [aws_s3control_access_grants_instance.this]
  iam_role_arn   = module.iam_role_clean_pickup[0].arn
  location_scope = "s3://${module.s3_bucket["clean"].s3_bucket_id}"
}

resource "aws_s3control_access_grant" "clean_pickup" {
  for_each                  = local.pickup_assignments
  access_grants_location_id = aws_s3control_access_grants_location.clean_pickup[0].access_grants_location_id
  permission                = "READ"
  access_grants_location_configuration { s3_sub_prefix = "${each.value.prefix}*" }
  grantee {
    grantee_type       = "DIRECTORY_${each.value.type}"
    grantee_identifier = each.value.id
  }
}

resource "aws_ssoadmin_application_assignment" "clean_pickup" {
  provider = aws.sso-application-assignment
  # Existing upload-group assignments remain owned by transfer-web-app.tf.
  for_each = { for key, assignments in local.pickup_principals : key => assignments[0]
    if !(assignments[0].type == "GROUP" && contains(values(local.transfer_iam_identity_center_groups), assignments[0].id))
  }
  application_arn = aws_transfer_web_app.this.identity_provider_details[0].identity_center_config[0].application_arn
  principal_id    = each.value.id
  principal_type  = each.value.type
}

module "iam_role_clean_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source          = "terraform-aws-modules/iam/aws//modules/iam-role"
  version         = "6.8.2"
  count           = length(local.pickup_recipients) > 0 ? 1 : 0
  name            = "transfer-clean-pickup"
  use_name_prefix = false
  trust_policy_permissions = {
    AccessGrants = {
      actions    = ["sts:AssumeRole", "sts:SetContext", "sts:SetSourceIdentity"]
      principals = [{ type = "Service", identifiers = ["access-grants.s3.amazonaws.com"] }]
      condition = [
        { test = "StringEquals", variable = "aws:SourceAccount", values = [data.aws_caller_identity.current.account_id] },
        { test = "ArnEquals", variable = "aws:SourceArn", values = [aws_s3control_access_grants_instance.this.access_grants_instance_arn] }
      ]
    }
  }
  policies = { pickup = module.iam_policy_clean_pickup[0].arn }
  tags     = local.tags
}

module "iam_policy_clean_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"
  count   = length(local.pickup_recipients) > 0 ? 1 : 0
  name    = "transfer-clean-pickup"
  policy  = data.aws_iam_policy_document.clean_pickup[0].json
  tags    = local.tags
}

data "aws_iam_policy_document" "clean_pickup" {
  count = length(local.pickup_recipients) > 0 ? 1 : 0
  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.s3_bucket["clean"].s3_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [for recipient in values(local.pickup_recipients) : "${recipient.prefix}*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
    }
  }
  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [for recipient in values(local.pickup_recipients) : "${module.s3_bucket["clean"].s3_bucket_arn}/${recipient.prefix}*"]
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = [aws_s3control_access_grants_instance.this.access_grants_instance_arn]
    }
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [module.kms_s3_bucket["clean"].key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Reject bearer query signatures issued with pickup-role credentials. Keep other
# service roles unaffected. Browser compatibility is a required onboarding test.
data "aws_iam_policy_document" "clean_pickup_no_presign" {
  count = length(local.pickup_recipients) > 0 ? 1 : 0
  statement {
    sid       = "DenyPickupPresignedDownloads"
    effect    = "Deny"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${local.application_name}-${local.environment}-clean/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [module.iam_role_clean_pickup[0].arn]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:authType"
      values   = ["REST-QUERY-STRING"]
    }
  }
}
