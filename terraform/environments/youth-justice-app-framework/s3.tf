module "s3" {
  source = "./modules/s3"

  environment_name = local.application_data.accounts[local.environment].environment_name

  bucket_name  = ["cms", "yjsm", "mis", "bedunlock", "bands", "cmm", "incident", "mis", "transfer"]
  project_name = local.project_name

  allow_replication = local.application_data.accounts[local.environment].allow_s3_replication
  s3_source_account = local.application_data.accounts[local.environment].source_account

  tags = local.tags
}
