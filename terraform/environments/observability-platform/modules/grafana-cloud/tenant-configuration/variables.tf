variable "tenants" {
  description = "Grafana Cloud tenants, keyed by tenant name. Defaults are applied here; see grafana-cloud-tenant-environment-configurations.tf for an example"
  type = map(object({
    # GitHub team synced to the tenant's Grafana team. A tenant without one has no team.
    github_team = optional(string)
    # AWS accounts owned by the tenant, keyed by account name
    aws_accounts = optional(map(object({
      # Must match the tenant module's grafana_cloud.pdc_agent.enabled in the account
      pdc_enabled = optional(bool, true)
      # Other tenants whose teams can also query the account's data
      shared_with_tenants = optional(list(string), [])
      cloudwatch = optional(object({
        enabled           = optional(bool, true)
        custom_namespaces = optional(list(string), [])
      }), {})
      # Opt in: Grafana Cloud Tempo is the preferred trace store
      xray = optional(object({
        enabled = optional(bool, false)
      }), {})
      # Amazon Managed Service for Prometheus workspace. No data source when unset.
      amazon_prometheus = optional(object({
        workspace_id = string
        region       = optional(string, "eu-west-2")
      }))
    })), {})
  }))

  validation {
    condition = (
      length(flatten([for tenant in values(var.tenants) : keys(tenant.aws_accounts)])) ==
      length(distinct(flatten([for tenant in values(var.tenants) : keys(tenant.aws_accounts)])))
    )
    error_message = "Each AWS account must belong to only one tenant. Use shared_with_tenants to give other tenants access."
  }

  validation {
    condition = alltrue(flatten([
      for tenant_name, tenant in var.tenants : [
        for account in values(tenant.aws_accounts) : [
          for shared_tenant in account.shared_with_tenants :
          shared_tenant != tenant_name && contains(keys(var.tenants), shared_tenant)
        ]
      ]
    ]))
    error_message = "shared_with_tenants must list other tenants in this configuration, not the owning tenant."
  }

  validation {
    condition = alltrue(flatten([
      for tenant in values(var.tenants) : [
        for account in values(tenant.aws_accounts) : [
          for namespace in account.cloudwatch.custom_namespaces : can(regex("^[0-9A-Za-z._/#: -]{1,255}$", namespace))
        ]
      ]
    ]))
    error_message = "Each cloudwatch.custom_namespaces item must be one CloudWatch namespace: up to 255 letters, digits, spaces and . - _ / # : characters."
  }

  validation {
    condition = alltrue(flatten([
      for tenant in values(var.tenants) : [
        for account in values(tenant.aws_accounts) :
        account.amazon_prometheus == null || (
          can(regex("^ws-[0-9a-f-]+$", account.amazon_prometheus.workspace_id)) &&
          can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", account.amazon_prometheus.region))
        )
      ]
    ]))
    error_message = "amazon_prometheus needs the workspace ID (ws-...) and an AWS region name, such as eu-west-2."
  }
}
