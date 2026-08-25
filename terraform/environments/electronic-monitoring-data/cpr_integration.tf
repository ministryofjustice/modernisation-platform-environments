locals {
    irsa_name = local.is-development || local.is-test ? "cloud-platform-irsa-8d7b7a42d840ce59-live" : ""
}

module "emd_cpr_integration_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    data.aws_iam_roles.mod_plat_roles.arns,
    "arn:aws:iam::754256621582:role/${local.irsa_name}",
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "emd_cpr_integration_${local.environment_shorthand}"

  tags = local.tags
}

data "aws_iam_policy_document" "cpr_integration" {
  statement {
    sid       = "ListAccountAliasForEnvironmentClass"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid    = "ListAllBucketsForEnvironmentClass"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAttributes",
      "s3:GetObject",
      "s3:DeleteObject"    
    ]
    resources = ["${module.s3-raw-formatted-data-bucket.bucket.arn}/staging/"]
  }
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      module.s3-raw-formatted-data-bucket.bucket.arn,
    ]
  }
}

resource "aws_glue_catalog_database" "person_record" {
    name = "person_record${local.db_suffix}"
    lifecycle {
        prevent_destroy = true
        ignore_changes = [
        description,
        location_uri,
        parameters,
        target_database
        ]
    }
}

resource "aws_iam_policy" "emd_cpr_integration_policy" {
  name_prefix = "emd-cpr-integrations"
  description = "Permissions for cpr integration."
  policy      = data.aws_iam_policy_document.cpr_integration.json
}

resource "aws_iam_role_policy_attachment" "emd_cpr_integration_permissions" {
  policy_arn = aws_iam_policy.emd_cpr_integration_policy.arn
  role       = module.emd_cpr_integration_role.iam_role_name
}
