locals {
  bu_accounts = jsondecode(file("${path.module}/../accounts.json"))

  mp_environments = concat(
    [
      "cloud-platform-preproduction",
      "cloud-platform-nonlive",
      "cloud-platform-live"
    ],
    local.bu_accounts.accounts
  )

  cp_vpc_name           = local.cluster_environment == "development_cluster" ? "cloud-platform-development" : terraform.workspace
  workspace_environment = element(reverse(split("-", terraform.workspace)), 0)
  cluster_name          = terraform.workspace
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"

  base_domain = "container-platform.service.justice.gov.uk"

  # Double trimprefix due to mix of cloud-platform- and container-platform- prefixes
  workspace_slug = trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")
  cluster_domain = contains(local.mp_environments, terraform.workspace) ? "${local.workspace_slug}.${local.base_domain}" : "${local.cluster_name}.development.${local.base_domain}"

  # Observability-specific configuration
  #
  # BU clusters are the workspaces named in business-units.json
  # amp_workspace_aliases (the shared source also used by the Grafana objects in
  # the root component). They write to the AMP workspace of that exact alias, so
  # the per-BU data source lookup finds it. Any other cluster (ephemeral dev)
  # keeps the per-cluster "<cluster>-metrics" workspace.
  #
  # Rollout is per BU and tier via amp_enabled in business-units.json, until AMP
  # is always on (#8517). Missing flags default to false.
  business_units           = jsondecode(file("${path.module}/../business-units.json")).business_units
  bu_amp_workspace_aliases = flatten([for bu in local.business_units : values(bu.amp_workspace_aliases)])
  is_bu_cluster            = contains(local.bu_amp_workspace_aliases, terraform.workspace)
  amp_workspace_alias      = local.is_bu_cluster ? terraform.workspace : "${local.cluster_name}-metrics"
  bu_amp_enabled = anytrue([
    for bu in local.business_units : anytrue([
      for tier, alias in bu.amp_workspace_aliases : alias == terraform.workspace && try(bu.amp_enabled[tier], false)
    ])
  ])

  # Observability feature flags — resolved from variables (default false, opt-in via -var flags).
  # AMP + ADOT is on for BU clusters enabled in business-units.json (bu_amp_enabled); other clusters opt in via the variable.
  # AMG is not deployed from this component; the centralised Grafana workspace
  # lives in the standalone `observability` component.
  enable_amp_adot                 = var.enable_amp_adot || local.bu_amp_enabled
  enable_cloudwatch_observability = var.enable_cloudwatch_observability
}
