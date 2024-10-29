module "replicated_cadet_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation?ref=0.5.0"
  data_locations = [{
    data_location = module.mojap_derived_tables_replication_bucket.s3_bucket_arn
    register      = true
    share         = true
    hybrid_mode   = false # will be managed exclusively in LakeFormation
  }]

  providers = {
    aws.source      = aws.analytical-platform-compute-eu-west-1
    aws.destination = aws
  }
}
