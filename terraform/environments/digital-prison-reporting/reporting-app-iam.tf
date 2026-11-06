# An AWS role for each reporting app deployment, assumed from its IRSA role in Cloud Platform.
# Each role can only read its own parent domain's data, and only use its own workgroup, results database and Redshift secret.

locals {
  # Where each reporting app's query results go in the working bucket. The app's role is limited to this prefix.
  reporting_app_athena_output_paths = {
    for app in ["prisons", "probation"] : app => "athena-output/reporting-${app}"
  }

  reporting_apps = {
    prisons = {
      irsa_role_name       = local.application_data.accounts[local.environment].reporting_app_irsa_role_names.prisons
      access_policy_arn    = aws_iam_policy.reporting_prisons_access.arn
      results_database     = "reports_prisons"
      athena_workgroup_arn = module.athena_workgroup_reporting_app["prisons"].arn
      athena_output_path   = local.reporting_app_athena_output_paths["prisons"]
    }
    probation = {
      irsa_role_name       = local.application_data.accounts[local.environment].reporting_app_irsa_role_names.probation
      access_policy_arn    = aws_iam_policy.reporting_probation_access.arn
      results_database     = "reports_probation"
      athena_workgroup_arn = module.athena_workgroup_reporting_app["probation"].arn
      athena_output_path   = local.reporting_app_athena_output_paths["probation"]
    }
  }

  # Until the reporting library can write each app's results to its own database, both apps write them to reports
  # This should be removed once the reporting app can write to a separate reports database per deployment.
  reporting_app_interim_results_database = "reports"

  # Federated query connectors for each domain's Postgres database. Not every domain has one.
  prisons_federated_query_function_arns = [
    for domain in local.dps_domains_list : "arn:aws:lambda:${local.account_region}:${local.account_id}:function:dpr-${domain}-federated-query-function"
  ]
  probation_federated_query_function_arns = [
    for domain in keys(local.probation_domains) : "arn:aws:lambda:${local.account_region}:${local.account_id}:function:dpr-${domain}-federated-query-function"
  ]

  glue_catalog_arn = "arn:aws:glue:${local.account_region}:${local.account_id}:catalog"

  cloud_platform_account_id = "754256621582"
}

# PARENT DOMAIN ACCESS
# --------------------

# Prisons

data "aws_iam_policy_document" "reporting_prisons_access" {
  statement {
    sid = "ReadPrisonsGlueTables"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = [
      local.glue_catalog_arn,
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${module.glue_prisons_database.db_name}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${module.glue_prisons_database.db_name}/*"
    ]
  }

  statement {
    sid     = "InvokePrisonsFederatedQueryConnectors"
    actions = ["lambda:InvokeFunction"]
    resources = concat(
      [module.athena_federated_query_connector_oracle.lambda_function_arn],
      local.prisons_federated_query_function_arns
    )
  }

  # For multiphase queries that read Redshift views.
  statement {
    sid       = "InvokeRedshiftFederatedQueryConnector"
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:${local.account_region}:${local.account_id}:function:dpr-athena-federated-query-redshift-function"]
  }
}

resource "aws_iam_policy" "reporting_prisons_access" {
  name        = "${local.project}-reporting-prisons-access"
  description = "Read access to the prisons parent domain's data for reporting"
  policy      = data.aws_iam_policy_document.reporting_prisons_access.json
}

# Probation

data "aws_iam_policy_document" "reporting_probation_access" {
  statement {
    sid = "ReadProbationGlueTables"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = [
      local.glue_catalog_arn,
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${module.glue_probation_database.db_name}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${module.glue_probation_database.db_name}/*"
    ]
  }

  statement {
    sid     = "InvokeProbationFederatedQueryConnectors"
    actions = ["lambda:InvokeFunction"]
    resources = concat(
      module.athena_federated_query_connector_oracle_probation[*].lambda_function_arn,
      local.probation_federated_query_function_arns
    )
  }
}

resource "aws_iam_policy" "reporting_probation_access" {
  name        = "${local.project}-reporting-probation-access"
  description = "Read access to the probation parent domain's data for reporting"
  policy      = data.aws_iam_policy_document.reporting_probation_access.json
}

# EACH DEPLOYMENT'S OWN RESOURCES
# -------------------------------

data "aws_iam_policy_document" "reporting_app_deployment" {
  for_each = local.reporting_apps

  statement {
    sid = "RunQueriesInOwnWorkgroup"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:GetWorkGroup"
    ]
    resources = [each.value.athena_workgroup_arn]
  }

  # Looking up any catalog is harmless. A query only reads data through a federated catalog if the role can invoke
  # its connector, and through AwsDataCatalog if the role can read the Glue tables.
  statement {
    sid       = "GetDataCatalogs"
    actions   = ["athena:GetDataCatalog"]
    resources = ["arn:aws:athena:${local.account_region}:${local.account_id}:datacatalog/*"]
  }

  statement {
    sid = "CreateResultTablesInOwnDatabase"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable",
      "glue:DeleteTable"
    ]
    resources = [
      local.glue_catalog_arn,
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${each.value.results_database}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${each.value.results_database}/*"
    ]
  }

  # We need an explicit deny due to allow policies elsewhere
  statement {
    sid    = "DenyGlueWritesElsewhere"
    effect = "Deny"
    actions = [
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:CreateSchema",
      "glue:DeleteSchema",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:DeleteDatabase"
    ]
    not_resources = [
      local.glue_catalog_arn,
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${each.value.results_database}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${each.value.results_database}/*",
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${local.reporting_app_interim_results_database}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${local.reporting_app_interim_results_database}/*"
    ]
  }

  statement {
    sid = "ManageOwnQueryResults"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["${module.s3_working_bucket.bucket_arn}/${each.value.athena_output_path}/*"]
  }

  statement {
    sid       = "ListOwnQueryResults"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_working_bucket.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [each.value.athena_output_path, "${each.value.athena_output_path}/*"]
    }
  }

  statement {
    sid       = "RunRedshiftStatements"
    actions   = ["redshift-data:ExecuteStatement"]
    resources = [module.datamart.cluster_arn]
  }

  statement {
    sid = "ReadOwnRedshiftSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.redshift_app_user[each.key].arn]
  }

  statement {
    sid       = "DecryptOwnRedshiftSecret"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.redshift-kms-key.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${local.account_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "reporting_app_deployment" {
  for_each = local.reporting_apps

  name        = "${local.project}-reporting-${each.key}-deployment"
  description = "The ${each.key} reporting app's own workgroup, results database and Redshift secret"
  policy      = data.aws_iam_policy_document.reporting_app_deployment[each.key].json
}

# SHARED BY BOTH APPS
# -------------------

data "aws_iam_policy_document" "reporting_app_common" {
  # Both parent domains' Glue tables point at these buckets, switching to temp-reload during a reload.
  # Which tables an app can read is limited in Glue instead of by direct bucket access.
  statement {
    sid     = "ListDataBuckets"
    actions = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [
      module.s3_curated_bucket.bucket_arn,
      module.s3_temp_reload_bucket.bucket_arn,
      module.s3_data_product_definitions_bucket.bucket_arn
    ]
  }

  statement {
    sid       = "GetWorkingBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.s3_working_bucket.bucket_arn]
  }

  statement {
    sid     = "ReadData"
    actions = ["s3:GetObject"]
    resources = [
      "${module.s3_curated_bucket.bucket_arn}/*",
      "${module.s3_temp_reload_bucket.bucket_arn}/*",
      "${module.s3_working_bucket.bucket_arn}/athena-spill/*",
      "${module.s3_data_product_definitions_bucket.bucket_arn}/*"
    ]
  }

  statement {
    sid       = "UseS3Key"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.s3.arn]
  }

  # These actions can't be limited by resource. The Data API only shows a caller the statements it ran.
  statement {
    sid = "TrackRedshiftStatements"
    actions = [
      "redshift-data:DescribeStatement",
      "redshift-data:GetStatementResult",
      "redshift-data:CancelStatement"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "reporting_app_common" {
  name        = "${local.project}-reporting-app-common"
  description = "Access every reporting app needs, whatever its parent domain"
  policy      = data.aws_iam_policy_document.reporting_app_common.json
}

# Access both apps need until the reporting library writes results to each app's own database, and the apps
# connect to Redshift as their own users
data "aws_iam_policy_document" "reporting_app_interim" {
  statement {
    sid = "CreateResultTablesInReports"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable"
    ]
    resources = [
      local.glue_catalog_arn,
      "arn:aws:glue:${local.account_region}:${local.account_id}:database/${local.reporting_app_interim_results_database}",
      "arn:aws:glue:${local.account_region}:${local.account_id}:table/${local.reporting_app_interim_results_database}/*"
    ]
  }

  statement {
    sid       = "ListRedshiftResults"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_working_bucket.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["reports/*"]
    }
  }

  statement {
    sid       = "ReadSharedRedshiftSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.datamart.credential_secret_arn]
  }
}

resource "aws_iam_policy" "reporting_app_interim" {
  name        = "${local.project}-reporting-app-interim"
  description = "The reporting apps' shared results database and Redshift secret, until each has its own"
  policy      = data.aws_iam_policy_document.reporting_app_interim.json
}

# ROLES
# -----

data "aws_iam_policy_document" "reporting_app_assume" {
  for_each = local.reporting_apps

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.cloud_platform_account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${local.cloud_platform_account_id}:role/${each.value.irsa_role_name}"]
    }
  }
}

resource "aws_iam_role" "reporting_app" {
  for_each = local.reporting_apps

  name                  = "${local.project}-reporting-${each.key}-role"
  description           = "The ${each.key} reporting app's role, assumed from its IRSA role in Cloud Platform"
  assume_role_policy    = data.aws_iam_policy_document.reporting_app_assume[each.key].json
  force_detach_policies = true

  tags = merge(
    local.all_tags,
    {
      dpr-name           = "${local.project}-reporting-${each.key}-role"
      dpr-resource-type  = "iam"
      dpr-jira           = "DHS-943"
      dpr-resource-group = "Front-End"
    }
  )
}

resource "aws_iam_role_policy_attachment" "reporting_app_access" {
  for_each = local.reporting_apps

  role       = aws_iam_role.reporting_app[each.key].name
  policy_arn = each.value.access_policy_arn
}

resource "aws_iam_role_policy_attachment" "reporting_app_deployment" {
  for_each = local.reporting_apps

  role       = aws_iam_role.reporting_app[each.key].name
  policy_arn = aws_iam_policy.reporting_app_deployment[each.key].arn
}

resource "aws_iam_role_policy_attachment" "reporting_app_common" {
  for_each = local.reporting_apps

  role       = aws_iam_role.reporting_app[each.key].name
  policy_arn = aws_iam_policy.reporting_app_common.arn
}

resource "aws_iam_role_policy_attachment" "reporting_app_interim" {
  for_each = local.reporting_apps

  role       = aws_iam_role.reporting_app[each.key].name
  policy_arn = aws_iam_policy.reporting_app_interim.arn
}

resource "aws_iam_role_policy_attachment" "reporting_app_dpd_table_read" {
  for_each = local.reporting_apps

  role       = aws_iam_role.reporting_app[each.key].name
  policy_arn = aws_iam_policy.dpd_table_read_policy.arn
}
