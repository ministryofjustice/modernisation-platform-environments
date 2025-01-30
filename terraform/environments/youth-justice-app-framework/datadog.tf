module "datadog" {
  source       = "./modules/datadog"
  project_name = local.project_name
  tags         = local.all_tags
}
