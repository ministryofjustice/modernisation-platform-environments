data "aws_iam_policy_document" "unscanned" {
  statement {
    sid    = "DenyGuardDutyTagWrites"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    # The S3 bucket module replaces the bucket placeholders with the created bucket ARN.
    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }
}

data "aws_iam_policy_document" "processing" {
  statement {
    sid    = "DenyGuardDutyTagWritesFromNonGuardDutyPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_configuration.guardduty_role_name}",
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagMutationFromNonGuardDutyPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_configuration.guardduty_role_name}",
      ]
    }

    condition {
      test     = "Null"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "clean" {
  statement {
    sid    = "DenyAccessToObjectsWithoutCleanGuardDutyStatus"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["NO_THREATS_FOUND"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagWritesFromNonFileMoverPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        module.lambda_processing_to_post_scan.lambda_role_arn,
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagMutationFromNonFileMoverPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        module.lambda_processing_to_post_scan.lambda_role_arn,
      ]
    }

    condition {
      test     = "Null"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "quarantine" {
  statement {
    sid    = "DenyAccessToObjectsWithoutCleanGuardDutyStatus"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["NO_THREATS_FOUND"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagWritesFromNonFileMoverPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        module.lambda_processing_to_post_scan.lambda_role_arn,
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagMutationFromNonFileMoverPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        module.lambda_processing_to_post_scan.lambda_role_arn,
      ]
    }

    condition {
      test     = "Null"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["false"]
    }
  }
}

