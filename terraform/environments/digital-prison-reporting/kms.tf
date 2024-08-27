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

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/${local.project}-s3-kms"
  target_key_id = aws_kms_key.s3.arn
}

### KINESIS KMS
resource "aws_kms_key" "kinesis-kms-key" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

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

resource "aws_kms_alias" "kinesis-kms-alias" {
  name          = "alias/${local.project}-kinesis-kms"
  target_key_id = aws_kms_key.kinesis-kms-key.arn
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
    local.tags,
    {
      Name = "${local.application_name}-rds-kms"
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
    local.tags,
    {
      Name = "${local.project}-operational-db-key"
    }
  )
}