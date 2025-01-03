module "s3" {
  source = "./modules/s3"

  bucket_name  = ["yjaf-development-cms", "yjaf-development-yjsm", "yjaf-development-mis", "yjaf-development-bedunlock", "yjaf-development-bands", "yjaf-development-cmm", "yjaf-development-incident", "yjaf-development-mis"]
  project_name = local.project_name

  tags = local.tags
}
