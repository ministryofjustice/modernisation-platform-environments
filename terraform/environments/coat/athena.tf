resource "aws_athena_workgroup" "coat_cur_report" {
  name = "coat_cur_report"

  configuration {
    result_configuration {
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
  }

  tags = local.tags
}

resource "aws_glue_catalog_database" "cur_v2_database" {
  name = "cur_v2_database"
}

resource "aws_iam_role" "glue_cur_role" {
  name = "glue_cur_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "glue_s3_policy" {
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  role = aws_iam_role.glue_cur_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly",
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = module.cur_s3_kms.key_arn
      },
      {
        Sid    = "AthenaAccess",
        Effect = "Allow",
        Action = [
          "athena:GetDatabase",
          "athena:GetDataCatalog",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetTableMetadata",
          "athena:GetWorkGroup",
          "athena:ListDatabases",
          "athena:ListDataCatalogs",
          "athena:ListWorkGroups",
          "athena:ListTableMetadata",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ],
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  role       = aws_iam_role.glue_cur_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_crawler" "cur_v2_crawler" {
  #checkov:skip=CKV_AWS_195: "Ensure Glue component has a security configuration associated"

  count = local.is-development ? 0 : 1

  name          = "cur_v2_crawler"
  database_name = aws_glue_catalog_database.cur_v2_database.name
  role          = aws_iam_role.glue_cur_role.arn

  s3_target {
    path = "s3://coat-${local.environment}-cur-v2-hourly/moj-cost-and-usage-reports/MOJ-CUR-V2-HOURLY/data/"
  }

  s3_target {
    path = "s3://coat-${local.environment}-cur-v2-hourly-enriched/"
  }

  configuration = jsonencode({
    Version = 1.0,
    CrawlerOutput = {
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })

  schedule = "cron(0 7 * * ? *)"
}

# Create derived table for ChatBot PoC
resource "aws_athena_named_query" "fct_daily_cost" {
  name     = "fct-daily-cost"
  database = aws_glue_catalog_database.cur_v2_database.name
  query = templatefile(
    "${path.module}/queries/fct_daily_cost.sql",
    {
      bucket = "coat-${local.environment}-cur-v2-hourly"
    }
  )
}

resource "null_resource" "execute_create_table_query" {
  count = local.is-development ? 0 : 1

  triggers = {
    query_ids   = aws_athena_named_query.fct_daily_cost.id
    script_hash = filesha256("${path.module}/queries/fct_daily_cost.sql")
  }

  provisioner "local-exec" {
    command = <<EOF
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::${data.aws_caller_identity.current.id}:role/MemberInfrastructureAccess --role-session-name github-actions-session)
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.fct_daily_cost.id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.coat_cur_report.name} \
  --result-configuration OutputLocation=s3://coat-${local.environment}-cur-v2-hourly/ctas/fct-daily-cost/ \
  --query-execution-context Database=${aws_glue_catalog_database.cur_v2_database.name} \
  --region ${data.aws_region.current.name}
EOF
  }

  depends_on = [aws_athena_named_query.fct_daily_cost]
}