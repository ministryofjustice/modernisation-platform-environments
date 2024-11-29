module "cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6ab6c596b45e90b3-live/aws-sdk-java-1732878337600"
  ]

  create_role = true

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
