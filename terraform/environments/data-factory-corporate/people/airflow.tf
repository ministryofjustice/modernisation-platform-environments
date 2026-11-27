# Create an empty secret; populate its JSON value manually before enabling.
resource "aws_secretsmanager_secret" "airflow-authentication" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a cluster OIDC identifier; automatic credential rotation is not applicable"
  name        = "external/analytical_platform/airflow_authentication"
  description = "Analytical Platform Compute OIDC cluster identifier for People Airflow workflows"
  kms_key_id  = module.corporate_general_kms_key.key_arn

  tags = local.tags
}

# Read the current secret value only after Airflow access is enabled.
data "aws_secretsmanager_secret_version" "airflow-authentication" {
  count     = local.enable_airflow_iam_role ? 1 : 0
  secret_id = aws_secretsmanager_secret.airflow-authentication.id
}

# Trust tokens from the Airflow EKS cluster. Reuse or import an existing provider.
resource "aws_iam_openid_connect_provider" "analytical-platform-compute" {
  count = local.enable_airflow_iam_role ? 1 : 0
  url   = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.airflow_oidc_cluster_identifier}"
  # Only accept tokens intended for AWS STS.
  client_id_list = ["sts.amazonaws.com"]
}

# Give the Airflow service account temporary credentials and scoped permissions.
module "data_platform_airflow_iam_role" {
  count  = local.enable_airflow_iam_role ? 1 : 0
  source = "./modules/airflow-iam-role"

  airflow_project         = "corp"
  airflow_workflow        = "data-factory"
  environment             = local.environment
  oidc_arn                = aws_iam_openid_connect_provider.analytical-platform-compute[0].arn
  role_name_suffix        = "data-ingestion"
  role_description        = "IAM role for People data ingestion Airflow workflows"
  oidc_cluster_identifier = local.airflow_oidc_cluster_identifier

  # Grant bucket listing, object access and KMS use for the landing bucket.
  iam_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:ListAllMyBuckets"]
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = ["s3:ListBucket"]
          Resource = module.sherlock_landing_bucket_mp.bucket.arn
        },
        {
          # Read/write all landing prefixes; no deletion or quarantine access.
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = "${module.sherlock_landing_bucket_mp.bucket.arn}/*"
        },
        {
          # Allow reads and writes encrypted with the landing bucket's KMS key.
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ]
          Resource = module.sherlock_kms_key.key_arn
          Condition = {
            StringEquals = {
              # Only allow KMS use through S3 in this region.
              "kms:ViaService" = "s3.${data.aws_region.current.region}.amazonaws.com"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "glue:GetDatabase",
            "glue:GetTable",
            "glue:CreateTable",
            "glue:UpdateTable"
          ]
          Resource = [
            local.glue_catalog_arn,
            module.sherlock_glue_database.glue_database_arn,
            "${replace(module.sherlock_glue_database.glue_database_arn, ":database/", ":table/")}/*"
          ]
        }
      ]
    })
  ]
}

resource "aws_lakeformation_permissions" "airflow-sherlock-database" {
  count = local.enable_airflow_iam_role ? 1 : 0

  principal   = module.data_platform_airflow_iam_role[0].role_arn
  permissions = ["DESCRIBE", "CREATE_TABLE"]

  database {
    name       = module.sherlock_glue_database.glue_database_name
    catalog_id = data.aws_caller_identity.current.account_id
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}

resource "aws_lakeformation_permissions" "airflow-sherlock-tables" {
  count = local.enable_airflow_iam_role ? 1 : 0

  principal   = module.data_platform_airflow_iam_role[0].role_arn
  permissions = ["DESCRIBE", "ALTER"]

  table {
    database_name = module.sherlock_glue_database.glue_database_name
    catalog_id    = data.aws_caller_identity.current.account_id
    wildcard      = true
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}

# The development smoke-test prefix is outside the Glue database's default location.
resource "aws_lakeformation_permissions" "airflow-sherlock-test-location" {
  count = local.enable_airflow_iam_role && local.environment == "development" ? 1 : 0

  principal   = module.data_platform_airflow_iam_role[0].role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn        = "${module.lakeformation_locations["sherlock"].location_arn}/airflow-test"
    catalog_id = data.aws_caller_identity.current.account_id
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}