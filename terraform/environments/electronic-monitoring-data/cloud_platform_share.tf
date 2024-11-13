module "front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::754256621582:root"
  ]

  create_role = true

  role_name = "read_emds_data"
}

module "share_api_data_marts" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation?ref=de5032cf43ad4a45049650342d39a1a85171c776"
  data_locations = [{
    data_location = module.s3-create-a-derived-table-bucket.bucket.arn
    register      = true
    share         = true
    hybrid_mode   = false # will be managed exclusively in LakeFormation
    principal     = module.front_end_assumable_role.role_arn
  }]

  databases_to_share = [{
    name      = "api_data_marts"
    principal = module.front_end_assumable_role.role_arn
  }]

  providers = {
    aws.source      = aws
    aws.destination = aws
  }
}
