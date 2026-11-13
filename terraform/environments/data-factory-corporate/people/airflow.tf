locals {
  # Apply with false, populate the secret, then set true and apply again.
  # Switching back to false removes the role and provider, but keeps the secret.
  enable_airflow_iam_role = true
}

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

locals {
  # Use the same cluster identifier for the provider and role trust policy.
  airflow_oidc_cluster_identifier = local.enable_airflow_iam_role ? jsondecode(data.aws_secretsmanager_secret_version.airflow-authentication[0].secret_string)["oidc_cluster_identifier"] : ""
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
  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/airflow-iam-role?ref=872286b442431969ac3bb8b44410c3e7a53b5c4e"

  # Trust mwaa:data-factory-corporate-data-ingestion (append -pp in preproduction).
  application_name        = local.application_name
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
          Action   = ["s3:ListBucket"]
          Resource = module.sherlock_landing_bucket_mp.bucket.arn
        },
        {
          # Read/write all landing prefixes; no deletion or quarantine access.
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
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