### S3 KMS
resource "aws_kms_key" "s3" {
  description         = "Encryption key for s3"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.s3-kms.json
  is_enabled          = true


  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-kms"
    }
  )
}

data "aws_iam_policy_document" "s3-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109       
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/${local.project}-s3-kms"
  target_key_id = aws_kms_key.s3.arn
}

### KINESIS KMS
resource "aws_kms_key" "kinesis-kms-key" {
  description         = "Encryption key for kinesis data stream"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.kinesis-kms.json
  is_enabled          = true


  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-kinesis-kms"
    }
  )
}

data "aws_iam_policy_document" "kinesis-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109       
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

resource "aws_kms_alias" "kinesis-kms-alias" {
  name          = "alias/${local.project}-kinesis-kms"
  target_key_id = aws_kms_key.kinesis-kms-key.arn
}

### Redshift KMS
resource "aws_kms_key" "redshift-kms-key" {
  description         = "Encryption key for Redshift Cluster"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.redhsift-kms.json
  is_enabled          = true  

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-redshift-kms"
    }
  )
}

data "aws_iam_policy_document" "redhsift-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109       
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

resource "aws_kms_alias" "redshift-kms-alias" {
  name          = "alias/${local.project}-redshift-kms"
  target_key_id = aws_kms_key.redshift-kms-key.arn
}