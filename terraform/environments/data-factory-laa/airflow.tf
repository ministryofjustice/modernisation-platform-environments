module "airflow_oidc" {
  source = "./modules/airflow-oidc"
}

module "cadet_role" {
  source = "./modules/cadet-role"

  identity_provider_arn = module.airflow_oidc.oidc_arn
}
