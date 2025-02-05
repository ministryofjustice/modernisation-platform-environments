module "app_servers" {
  source = "./cwa-poc2"

  environment = local.environment
  application_data = local.application_data
  tags = local.tags
  # Pass other variables as needed...
}