locals {
  #if envinment is dev set to dev, prod set to prod, preprod set to preprod
  datadog_integration_external_id = {
    "prod"    = ""
    "preprod" = ""
    "development"     = "a43e2b2de71041889dbb5d2cd8170356"
    "test"      = ""
  }
}

module "datadog" {
  source       = "./modules/datadog"
  project_name = local.project_name
  datadog_integration_external_id = local.datadog_integration_external_id[local.environment]
  tags         = local.tags
}
