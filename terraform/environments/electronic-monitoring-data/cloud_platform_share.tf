locals {
  # Setting the IAM name that our Cloud Platform API will use to connect to this role

  iam-dev     = local.environment_shorthand == "dev" ? var.cloud-platform-iam-dev : ""
  iam-test    = local.environment_shorthand == "test" ? var.cloud-platform-iam-preprod : ""
  iam-preprod = local.environment_shorthand == "preprod" ? var.cloud-platform-iam-preprod : ""
  iam-prod    = local.environment_shorthand == "prod" ? var.cloud-platform-iam-prod : ""

  resolved-cloud-platform-iam-role = coalesce(local.iam-dev, local.iam-test, local.iam-preprod, local.iam-prod)
}

variable "cloud-platform-iam-dev" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-6ab6c596b45e90b3-live"
}

variable "cloud-platform-iam-preprod" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-bca231f5681d29c6-live"
}

variable "cloud-platform-iam-prod" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-7a81f92a48491ef0-live"
}

module "cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.0"

  trusted_role_arns = [
    local.resolved-cloud-platform-iam-role
  ]

  create_role       = true
  role_requires_mfa = false

  role_name = "cmt_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

# module "share_api_data_marts" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
#   source = "github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation?ref=32525da937012178e430585ac5a00f05193f58eb"
#   data_locations = [{
#     data_location = module.s3-create-a-derived-table-bucket.bucket.arn
#     register      = true
#     share         = true
#     hybrid_mode   = false # will be managed exclusively in LakeFormation
#     principal     = module.cmt_front_end_assumable_role.iam_role_arn
#   }]

#   databases_to_share = [{
#     name      = "api_data_marts"
#     principal = module.cmt_front_end_assumable_role.iam_role_arn
#   }]

#   providers = {
#     aws.source      = aws
#     aws.destination = aws
#   }
# }
