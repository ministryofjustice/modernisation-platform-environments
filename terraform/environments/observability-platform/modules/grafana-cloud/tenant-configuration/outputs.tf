# Neither output includes account IDs: they are sensitive, and a sensitive output can't be used in
# for_each. Look them up by account name where they are needed.

output "accounts" {
  description = "AWS accounts with defaults applied, keyed by account name. Adds the owning `tenant` and `query_tenants`: the owning tenant followed by the tenants the account is shared with"
  value       = local.accounts
}

output "tenants" {
  description = "Tenants keyed by tenant name, with their `github_team` and `query_accounts`: the accounts the tenant can query, its own and those shared with it"
  value = {
    for tenant_name, tenant in var.tenants : tenant_name => {
      github_team    = tenant.github_team
      query_accounts = sort([for account in values(local.accounts) : account.name if contains(account.query_tenants, tenant_name)])
    }
  }
}
