locals {
  missing_report_db_credentials = jsondecode(aws_secretsmanager_secret_version.missing_report_submissions.secret_string)
}

resource "aws_kms_key" "missing_report_submissions" {
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
      dpr-jira          = "DPR2-2007"
    }
  )
}

data "aws_iam_policy_document" "missing_report_submissions" {
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

resource "aws_kms_alias" "missing_report_submissions" {
  name          = "alias/${local.project}-missing-report-submissions-kms"
  target_key_id = aws_kms_key.missing_report_submissions.arn
}

resource "aws_secretsmanager_secret" "missing_report_submissions" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "external/${local.project}-missing-report-submissions-source-secrets"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-missing-report-submissions-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-2007"
    }
  )
}

resource "random_password" "missing_report_submissions" {
  length  = 16
  special = false
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "missing_report_submissions" {
  secret_id = aws_secretsmanager_secret.missing_report_submissions.id
  secret_string = jsonencode({
    username = "dpradmin"
    password = random_password.missing_report_submissions.result
  })
}
data "aws_iam_policy_document" "missing_report_submissions-kms" {
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

resource "aws_kms_alias" "missing_report_submissions-kms-alias" {
  name          = "alias/${local.project}-missing_report_submissions-kms"
  target_key_id = aws_kms_key.missing_report_submissions.arn
}

module "aurora_missing_report_submissions" {
  source = "./modules/rds/aws-aurora/"

  name                        = "${local.application_data.accounts[local.environment].missing_report_submissions_rds.name}-${local.environment}-cluster"
  engine                      = local.application_data.accounts[local.environment].missing_report_submissions_rds.engine
  engine_version              = local.application_data.accounts[local.environment].missing_report_submissions_rds.engine_version
  database_name               = local.application_data.accounts[local.environment].missing_report_submissions_rds.db_identifier
  manage_master_user_password = false
  master_username             = local.missing_report_db_credentials.username
  master_password             = local.missing_report_db_credentials.password
  instances = {
    1 = {
      identifier     = "${local.application_data.accounts[local.environment].missing_report_submissions_rds.name}-${local.environment}"
      instance_class = local.application_data.accounts[local.environment].missing_report_submissions_rds.inst_class
    }
  }

  endpoints = {
    static = {
      identifier     = "missing-report-static-any-endpoint"
      type           = "ANY"
      static_members = ["${local.application_data.accounts[local.environment].missing_report_submissions_rds.name}-${local.environment}"]
      tags           = { Endpoint = "Missing-Report-Any" }
    }
  }

  ca_cert_identifier = "rds-ca-rsa2048-g1" # Updated on 29th July 2024

  vpc_id = data.aws_vpc.shared.id
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [data.aws_vpc.dpr.cidr_block]
    }
    egress_example = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Egress to all"
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  create_db_subnet_group = true
  subnets                = local.dpr_subnets

  db_parameter_group_name         = "default.aurora-postgresql16"
  db_cluster_parameter_group_name = "default.aurora-postgresql16"

  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true

  create_db_cluster_activity_stream     = false
  db_cluster_activity_stream_kms_key_id = aws_kms_key.missing_report_submissions.key_id
  db_cluster_activity_stream_mode       = "async"

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "missing_report_submissions-DB"
      dpr-resource-type  = "RDS"
      dpr-jira           = "DPR2-2007"
      project        = local.project
      dpr-name           = "missing_report_submissions"
    }
  )
}
