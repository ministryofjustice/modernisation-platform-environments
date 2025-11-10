### S3 KMS
resource "aws_kms_key" "s3" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for s3"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.s3-kms.json
  is_enabled          = true


  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.application_name}-s3-kms"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DPR2-XXXX"
    }
  )
}

data "aws_iam_policy_document" "s3-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_358
    #checkov:skip=CKV_AWS_107
    #checkov:skip=CKV_AWS_1
    #checkov:skip=CKV_AWS_356
    #checkov:skip=CKV_AWS_283
    #checkov:skip=CKV_AWS_49
    #checkov:skip=CKV_AWS_108
    #checkov:skip=CKV_AWS_110   

    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
      ]
    }
  }
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/${local.project}-s3-kms"
  target_key_id = aws_kms_key.s3.arn
}

### Redshift KMS
resource "aws_kms_key" "redshift-kms-key" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for Redshift Cluster"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.redhsift-kms.json
  is_enabled          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.application_name}-redshift-kms"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DPR2-XXXX"
    }
  )
}

data "aws_iam_policy_document" "redhsift-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_110
    #checkov:skip=CKV_AWS_358
    #checkov:skip=CKV_AWS_107
    #checkov:skip=CKV_AWS_1 
    #checkov:skip=CKV_AWS_283
    #checkov:skip=CKV_AWS_49
    #checkov:skip=CKV_AWS_108
    #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"   
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_alias" "redshift-kms-alias" {
  name          = "alias/${local.project}-redshift-kms"
  target_key_id = aws_kms_key.redshift-kms-key.arn
}

### RDS, Postgres KMS
resource "aws_kms_key" "rds" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for RDS Instance"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.rds-kms.json
  is_enabled          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.application_name}-rds-kms"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DPR2-XXXX"
    }
  )
}

data "aws_iam_policy_document" "rds-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_110
    #checkov:skip=CKV_AWS_358
    #checkov:skip=CKV_AWS_107
    #checkov:skip=CKV_AWS_1 
    #checkov:skip=CKV_AWS_283
    #checkov:skip=CKV_AWS_49
    #checkov:skip=CKV_AWS_108
    #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"         
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_alias" "rds-kms-alias" {
  name          = "alias/${local.project}-rds-kms"
  target_key_id = aws_kms_key.rds.arn
}

# RDS Database Key
resource "aws_kms_key" "operational_db" {
  #checkov:skip=CKV2_AWS_64: "Ensure KMS key Policy is defined"
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for Operational DB"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  is_enabled          = true


  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-operational-db-key"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DPR2-XXXX"
    }
  )
}

### CLOUDTRAIL KMS
resource "aws_kms_key" "cloudtrail" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for cloudtrail"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.cloudtrail-kms.json
  is_enabled          = true


  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.application_name}-cloudtrail-kms"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DPR2-XXXX"
    }
  )
}

data "aws_iam_policy_document" "cloudtrail-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_358
    #checkov:skip=CKV_AWS_107
    #checkov:skip=CKV_AWS_1
    #checkov:skip=CKV_AWS_356
    #checkov:skip=CKV_AWS_283
    #checkov:skip=CKV_AWS_49
    #checkov:skip=CKV_AWS_108
    #checkov:skip=CKV_AWS_110   

    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
