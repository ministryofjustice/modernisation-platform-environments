data "aws_s3_bucket" "incoming" {
  count = local.create_test_harness ? 1 : 0

  bucket = local.incoming_bucket_name
}

data "aws_kms_key" "incoming" {
  count = local.create_test_harness ? 1 : 0

  key_id = local.incoming_kms_key_alias
}

data "aws_s3_bucket" "clean" {
  count = local.create_test_harness ? 1 : 0

  bucket = local.clean_bucket_name
}

data "aws_kms_alias" "hosted_pickup" {
  count = local.create_test_harness ? 1 : 0

  name = local.hosted_pickup_kms_key_alias
}

data "aws_iam_policy_document" "test_harness_trust" {
  count = local.create_test_harness ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:ministryofjustice/integration-hub:environment:smoke-test",
        "repo:ministryofjustice/modernisation-platform-environments:environment:smoke-test"
      ]
    }
  }
}

module "iam_role_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  create          = local.create_test_harness
  use_name_prefix = false
  name            = local.test_harness_iam_name

  source_trust_policy_documents = local.test_harness_trust_policy_documents

  policies = {
    smoke_test = module.iam_policy_test_harness.arn
  }

  tags = local.tags
}

data "aws_iam_policy_document" "test_harness_permissions" {
  count = local.create_test_harness ? 1 : 0

  statement {
    sid     = "UploadSmokeTestFixture"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      for prefix in local.incoming_prefixes : "${data.aws_s3_bucket.incoming[0].arn}/${prefix}*"
    ]
  }

  statement {
    sid       = "EncryptSmokeTestFixture"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
    resources = [data.aws_kms_key.incoming[0].arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        for prefix in local.incoming_prefixes : "${data.aws_s3_bucket.incoming[0].arn}/${prefix}*"
      ]
    }
  }

  statement {
    sid       = "CheckSmokeTestDelivery"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_test_harness.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.push_to_s3_destination_prefix}*"]
    }
  }

  statement {
    sid       = "ReadDeliveredFixture"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_test_harness.s3_bucket_arn}/${local.push_to_s3_destination_prefix}*"]
  }

  statement {
    sid       = "ListTestCleanObjectVersions"
    effect    = "Allow"
    actions   = ["s3:ListBucketVersions"]
    resources = [data.aws_s3_bucket.clean[0].arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [for prefix in local.incoming_prefixes : "${prefix}*"]
    }
  }

  statement {
    sid       = "DescribeTestDispatchConfiguration"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret"]
    resources = local.test_dispatch_secret_arns
  }

  statement {
    sid     = "InvokeTestWriters"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      local.test_writer_function_arn,
      local.test_hosted_pickup_function_arn,
    ]
  }

  statement {
    sid       = "CheckHostedPickupDelivery"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.hosted_pickup_bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.hosted_pickup_destination_prefix}*"]
    }
  }

  statement {
    sid       = "ReadHostedPickupDelivery"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.hosted_pickup_bucket_name}/${local.hosted_pickup_destination_prefix}*"]
  }

  statement {
    sid       = "ReadHostedPickupRetention"
    effect    = "Allow"
    actions   = ["s3:GetLifecycleConfiguration"]
    resources = ["arn:aws:s3:::${local.hosted_pickup_bucket_name}"]
  }

  statement {
    sid       = "DecryptHostedPickupDelivery"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.hosted_pickup[0].target_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    # The hosted bucket uses S3 Bucket Keys, so the encryption context is the bucket ARN.
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.hosted_pickup_bucket_name}"]
    }
  }

  # List only: the access-control test needs AccessDenied, not NoSuchKey, when it tries to read.
  # Do not add s3:GetObject here; the test asserts that this role cannot read recipient files.
  statement {
    sid       = "FindPresignedPickupCopy"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.presigned_pickup_bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.presigned_recipient_id}/*"]
    }
  }

  statement {
    sid       = "ReadPresignedAccessGrants"
    effect    = "Allow"
    actions   = ["s3:ListAccessGrants"]
    resources = ["arn:aws:s3:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:access-grants/default"]
  }

  statement {
    sid       = "DecryptDeliveredFixture"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_test_harness.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.s3_test_harness.s3_bucket_arn}/${local.push_to_s3_destination_prefix}*"]
    }
  }
}

module "iam_policy_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  create      = local.create_test_harness
  name        = local.test_harness_iam_name
  description = "Upload and verify Integration Hub repository smoke-test fixtures"
  policy      = local.create_test_harness ? data.aws_iam_policy_document.test_harness_permissions[0].json : null

  tags = local.tags
}