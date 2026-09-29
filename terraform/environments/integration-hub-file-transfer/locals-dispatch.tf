module "file_dispatch_configuration" {
  source = "./modules/file-dispatch-configuration"

  environment = local.environment
}

locals {
  file_dispatch_secret_name_prefix = "${local.application_name}/file-dispatch/"

  file_dispatch_prefixes = module.file_dispatch_configuration.prefixes

  environment_file_dispatch_prefixes = [
    for identity, prefixes in local.file_dispatch_prefixes : {
      for prefix, configuration in prefixes :
      "${local.file_dispatch_secret_name_prefix}${identity}${prefix}" => configuration
    }
  ]
}