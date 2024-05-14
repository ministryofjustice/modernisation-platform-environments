data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "dms_dv_parquet_s3_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.dms_dv_parquet_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_parquet_s3_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

data "aws_iam_policy_document" "dms_dv_s3_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*",
      aws_s3_bucket.dms_target_ep_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_glue_job_s3_bucket.arn}/*",
      aws_s3_bucket.dms_dv_glue_job_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_parquet_s3_bucket.arn}/*",
      aws_s3_bucket.dms_dv_parquet_s3_bucket.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.dms_dv_parquet_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_parquet_s3_bucket.arn}/*",
      aws_s3_bucket.dms_dv_glue_job_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_glue_job_s3_bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "dms_dv_athena_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "athena:TerminateSession",
      "athena:CreateDataCatalog",
      "athena:UpdateDataCatalog",
      "athena:GetTableMetadata",
      "athena:StartQueryExecution",
      "athena:GetSession",
      "athena:DeleteWorkGroup",
      "athena:GetQueryResults",
      "athena:GetDatabase",
      "athena:GetDataCatalog",
      "athena:UpdateWorkGroup",
      "athena:CreateWorkGroup",
      "athena:ListQueryExecutions",
      "athena:ListSessions",
      "athena:GetWorkGroup",
      "athena:ListDatabases",
      "athena:GetSessionStatus",
      "athena:StopQueryExecution",
      "athena:DeleteDataCatalog",
      "athena:GetQueryExecution",
      "athena:StartSession",
      "athena:ListTableMetadata"
    ]
    resources = [
      "arn:aws:athena:*:*:workgroup/*",
      "arn:aws:athena:*:*:datacatalog/dms_data_validation/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "athena:GetNamespaces",
      "athena:ListDataCatalogs",
      "athena:GetExecutionEngine",
      "athena:GetNamespace",
      "athena:GetQueryExecutions",
      "athena:GetExecutionEngines",
      "athena:GetTables",
      "athena:GetTable",
      "athena:ListExecutors",
      "athena:RunQuery",
      "athena:GetCatalogs"
    ]
    resources = [
      "*"
    ]
  }
}
