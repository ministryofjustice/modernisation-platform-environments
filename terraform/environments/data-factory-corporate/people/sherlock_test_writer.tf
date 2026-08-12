# -----------------------------------------------------------------------------
# Sherlock test writer role (TEST WORKSPACE ONLY)
# -----------------------------------------------------------------------------
# Temporary, same-account IAM role used to validate the Sherlock S3/KMS write
# path in the corp test account. This mirrors the Avature spec's same-account
# resource-access model (rather than the throwaway cross-account dev->corp
# assume-role config), so a successful KMS-encrypted write here validates the
# policy shape that the production Avature role will use.
#
# Gated with `count = local.is-test ? 1 : 0` so it ONLY exists in the -test
# workspace and can never be created in dev/preprod/prod. Delete this file once
# testing is complete.
#
# NOTE ON PREFIX: the S3 object statement below is scoped to
# `<bucket>/avature-sherlock/*` to match the `s3_prefix` used by the production
# `assume_iam_role` module in main.tf. If that prefix changes (e.g. to the
# spec's `data/*`), update BOTH together so the test remains meaningful.
#
# NOTE ON KMS: the identity-side kms:* permissions here are not sufficient on
# their own. The `sherlock_kms_key` key policy must also allow this role (or
# delegate to IAM via a default key policy), otherwise writes fail AccessDenied.

data "aws_iam_policy_document" "sherlock_test_writer_trust" {
  count = local.is-test ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    # Restrict to the collaborator/SSO principals in this account. Adjust the
    # ArnLike value to the specific SSO permission set or role you will assume
    # from when running the write test.
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
      ]
    }
  }
}

resource "aws_iam_role" "sherlock_test_writer" {
  count              = local.is-test ? 1 : 0
  name               = "sherlock_test_writer"
  assume_role_policy = data.aws_iam_policy_document.sherlock_test_writer_trust[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "sherlock_test_writer_s3_kms" {
  count = local.is-test ? 1 : 0
  name  = "sherlock-test-writer-s3-kms"
  role  = aws_iam_role.sherlock_test_writer[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.sherlock_landing_bucket_test.bucket.arn
      },
      {
        Sid      = "ObjectReadWrite"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.sherlock_landing_bucket_test.bucket.arn}/avature-sherlock/*"
      },
      {
        Sid      = "KmsEncryptDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:ReEncrypt*"]
        Resource = module.sherlock_kms_key.key_arn
      }
    ]
  })
}
