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

data "aws_iam_policy_document" "glue_mig_and_val_s3_iam_policy_document" {
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
      "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*",
      aws_s3_bucket.dms_target_ep_s3_bucket.arn,
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
      "athena:StartQueryExecution",
      "athena:GetQueryExecution"
    ]
    resources = [
      "arn:aws:athena:eu-west-2:${local.modernisation_platform_account_id}:workgroup/primary",
      "arn:aws:athena:eu-west-2:${local.modernisation_platform_account_id}:datacatalog/dms_data_validation/*",
      "arn:aws:athena:eu-west-2:800964199911:workgroup/primary",
      "arn:aws:athena:eu-west-2:800964199911:datacatalog/dms_data_validation/*",
      "arn:aws:athena:eu-west-2:976799291502:workgroup/primary",
      "arn:aws:athena:eu-west-2:976799291502:datacatalog/dms_data_validation/*"
    ]
  }
}

data "aws_iam_policy_document" "glue_notebook_ec2_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
}
