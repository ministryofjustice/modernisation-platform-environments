locals {
  # Account name => account configuration, with its owning tenant and every tenant that can query it
  accounts = {
    for account in flatten([
      for tenant_name, tenant in var.tenants : [
        for account_name, account in tenant.aws_accounts : merge(account, {
          name          = account_name
          tenant        = tenant_name
          query_tenants = distinct(concat([tenant_name], account.shared_with_tenants))
        })
      ]
    ]) : account.name => account
  }
}
