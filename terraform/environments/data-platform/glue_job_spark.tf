
locals {
  default_arguments = {
    "--continuous-log-logGroup" = aws_cloudwatch_log_group.log_group.name
  }
}


# load the glue script to bucket as bucket object
resource "aws_s3_object" "object" {
  bucket      = module.s3-bucket.bucket.id
  key         = "glue_script/glue_spark_transform_script.py"
  source      = "glue_script/glue_spark_transform_script.py"
  source_hash = filemd5("glue_script/glue_spark_transform_script.py")
}

resource "aws_glue_job" "glue_job" {
  name                   = "${local.name}-glue-job-${local.environment}"
  role_arn               = aws_iam_role.glue-service-role.arn
  description            = "Glue job to transform and load data products to the glue catalog"
  glue_version           = local.glue_version
  max_retries            = local.max_retries
  security_configuration = aws_glue_security_configuration.sec_cfg.id
  worker_type            = local.worker_type
  number_of_workers      = local.number_of_workers
  timeout                = local.timeout
  execution_class        = local.execution_class
  tags                   = local.tags

  command {
    script_location = "s3://${module.s3-bucket.bucket.id}/glue_script/glue_spark_transform_script.py"
    name            = "glueetl"
  }

  default_arguments = merge(local.glue_default_arguments, local.default_arguments)

  execution_property {
    max_concurrent_runs = local.max_concurrent
  }
}

### Glue Job Service Role
resource "aws_iam_role" "glue-service-role" {
  name               = "${local.name}-glue-role-${local.environment}"
  tags               = local.tags
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.glue_role_trust_policy.json
}

data "aws_iam_policy_document" "glue_role_trust_policy" {
  statement {
    sid     = "GlueAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "glue-service-policy" {
  name       = "${local.name}-role-attach-${local.environment}"
  roles      = [aws_iam_role.glue-service-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy_document" "s3-access" {
  statement {
    sid = "GETPUTBucketAccess"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:ListBucket*",
    ]
    resources = [
      "${module.s3-bucket.bucket.arn}/*",
      "${module.s3-bucket.bucket.arn}"
    ]
  }
}

resource "aws_iam_policy" "s3_policy_for_gluejob" {
  name        = "${local.name}-s3-policy-${local.environment}"
  path        = "/"
  description = "s3 permissions for data product transform glue job"
  policy      = data.aws_iam_policy_document.s3-access.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "s3_access_for_glue_job" {
  role       = aws_iam_role.glue-service-role.name
  policy_arn = aws_iam_policy.s3_policy_for_gluejob.arn
}

data "aws_iam_policy_document" "glue_athena_access" {
  statement {
    sid = "QueryAccess"
    actions = [
      "athena:StartQueryExecution",
    ]
    resources = [
      "arn:aws:athena:*:${data.aws_caller_identity.current.account_id}:workgroup/*"
    ]
  }
}

resource "aws_iam_policy" "athena_policy_for_gluejob" {
  name        = "${local.name}-athena-policy-${local.environment}"
  path        = "/"
  description = "Athena permissions for data product transform glue job"
  policy      = data.aws_iam_policy_document.glue_athena_access.json

}

resource "aws_iam_role_policy_attachment" "athena_access_for_glue_job" {
  role       = aws_iam_role.glue-service-role.name
  policy_arn = aws_iam_policy.athena_policy_for_gluejob.arn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws-glue/jobs/${local.name}-${local.environment}"
  retention_in_days = local.glue_log_group_retention_in_days
  tags              = local.tags
}

resource "aws_glue_security_configuration" "sec_cfg" {
  name = "${local.name}-sec-config-${local.environment}"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
}
