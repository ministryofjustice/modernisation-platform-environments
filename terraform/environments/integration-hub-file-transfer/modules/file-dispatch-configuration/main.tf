locals {
  file_dispatch_prefixes = {
    development   = local.development
    test          = local.test
    preproduction = local.preproduction
    production    = local.production
  }

  entries = merge({}, [
    for identity, prefixes in local.file_dispatch_prefixes[var.environment] : {
      for source_prefix, configuration in prefixes :
      "${identity}${source_prefix}" => {
        identity      = identity
        source_prefix = source_prefix
        name_suffix   = join("-", compact(split("/", "${identity}${source_prefix}")))
        action        = configuration.action
      }
    }
  ]...)
}