locals {
  # AP Airflow production EKS issuer; both workflows below run on this cluster.
  ap_compute_oidc_host = "oidc.eks.eu-west-2.amazonaws.com/id/801920EDEF91E3CAB03E04C03A2DE2BB"
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute" {
  count = local.is-production ? 1 : 0

  url            = "https://${local.ap_compute_oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  tags           = local.tags
}

resource "aws_iam_role" "ap_airflow_redshift_ingestion" {
  count = local.is-production ? 1 : 0

  name        = "ap-airflow-redshift-ingestion"
  description = "Assumed by AP Airflow to extract Redshift data via the Data API"
  tags        = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.analytical_platform_compute[0].arn
      }
      Condition = {
        StringEquals = {
          "${local.ap_compute_oidc_host}:aud" = "sts.amazonaws.com"
          "${local.ap_compute_oidc_host}:sub" = [
            "system:serviceaccount:mwaa:yjb-redshift-ingestion",
            "system:serviceaccount:mwaa:yjb-redshift-ingestion-dev",
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ap_airflow_redshift_ingestion" {
  count = local.is-production ? 1 : 0

  name = "redshift-data-api"
  role = aws_iam_role.ap_airflow_redshift_ingestion[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "redshift-serverless:GetCredentials",
          "redshift-data:ExecuteStatement",
        ]
        Resource = module.redshift.workgroup_arn
      },
      {
        Effect = "Allow"
        Action = [
          "redshift-data:CancelStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "redshift-data:statement-owner-iam-userid" = "$${aws:userid}"
          }
        }
      },
    ]
  })
}

output "ap_airflow_redshift_ingestion_role_arn" {
  description = "Use as iam.external_role in the AP Airflow workflow.yml"
  value       = one(aws_iam_role.ap_airflow_redshift_ingestion[*].arn)
}
