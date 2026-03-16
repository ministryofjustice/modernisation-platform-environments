module "viewpoint_cde_prisons" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_prefix      = "viewpoint-cde-prisons-"
  versioning_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

data "aws_iam_policy_document" "airflow_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.analytical_platform_compute.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "airflow_cde" {
  name                  = "airflow-cde"
  description           = "Role to allow Airflow to run CDE jobs"
  assume_role_policy    = data.aws_iam_policy_document.airflow_assume_role.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "airflow_cde_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]
    resources = [
      "${module.viewpoint_cde_prisons.bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "airflow_cde_s3" {
  name        = "airflow-cde-s3-policy"
  description = "Policy to allow Airflow to put/update objects in the CDE prisons bucket"
  policy      = data.aws_iam_policy_document.airflow_cde_s3.json
}

resource "aws_iam_role_policy_attachment" "airflow_cde_s3" {
  role       = aws_iam_role.airflow_cde.name
  policy_arn = aws_iam_policy.airflow_cde_s3.arn
}

data "aws_iam_policy_document" "airflow_cde_bedrock" {
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:*:*:inference-profile/*",
      "arn:aws:bedrock:*::foundation-model/*"
    ]
  }
}

resource "aws_iam_policy" "airflow_cde_bedrock" {
  name        = "airflow-cde-bedrock-policy"
  description = "Policy to allow Airflow to invoke Bedrock models with cross-region inference"
  policy      = data.aws_iam_policy_document.airflow_cde_bedrock.json
}

resource "aws_iam_role_policy_attachment" "airflow_cde_bedrock" {
  role       = aws_iam_role.airflow_cde.name
  policy_arn = aws_iam_policy.airflow_cde_bedrock.arn
}
