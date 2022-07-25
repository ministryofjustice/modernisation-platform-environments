module "backup" {
  count       = local.accounts[local.environment].backup == null ? 0 : 1
  source      = "./modules/backup"
  key         = local.accounts[local.environment].backup.key
  value       = local.accounts[local.environment].backup.value
  rules       = try(local.accounts[local.environment].backup.rules, [])
  environment = local.environment
  tags        = local.tags

}