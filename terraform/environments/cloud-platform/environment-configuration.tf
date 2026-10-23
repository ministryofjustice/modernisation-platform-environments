locals {
  environment_configurations = {
    cloud-platform-development = {
      account_subdomain_name = "development.${local.base_domain}"
      # Phase-2 gate for the Grafana provider (see local.grafana_objects_enabled).
      #
      # Now true (phase 2): the phase-1 apply created the iac-grafana-objects
      # service account (amg.tf), so the pipeline can mint a token and the
      # grafana_* objects (BU teams, data sources, data-source permissions,
      # folders) can be created. This must NOT be set true before the service
      # account exists — doing so reintroduces the bootstrap cycle, where
      # Terraform plans the service account and the Grafana objects in one pass
      # but the provider has no token yet and fails with "missing a
      # configuration for the Grafana API".
      #
      # Bring-up sequence for a fresh AMG host workspace: (1) apply with false to
      # create the service account, (2) then set true and apply again. Other AMG
      # host workspaces (e.g. cloud-platform-live) follow the same two steps.
      grafana_objects_enabled = true
    }
    cloud-platform-preproduction = {
      account_subdomain_name = "preproduction.${local.base_domain}"
    }
    cloud-platform-nonlive = {
      account_subdomain_name = "nonlive.${local.base_domain}"
    }
    cloud-platform-live = {
      account_subdomain_name = "live.${local.base_domain}"
    }
    container-platform-octo-nonlive = {
      account_subdomain_name = "octo-nonlive.${local.base_domain}"
    }
    container-platform-octo-live = {
      account_subdomain_name = "octo-live.${local.base_domain}"
    }
    container-platform-laa-nonlive = {
      account_subdomain_name = "laa-nonlive.${local.base_domain}"
    }
    container-platform-laa-live = {
      account_subdomain_name = "laa-live.${local.base_domain}"
    }
    container-platform-hmpps-nonlive = {
      account_subdomain_name = "hmpps-nonlive.${local.base_domain}"
    }
    container-platform-hmpps-live = {
      account_subdomain_name = "hmpps-live.${local.base_domain}"
    }
    container-platform-cd-nonlive = {
      account_subdomain_name = "cd-nonlive.${local.base_domain}"
    }
    container-platform-cd-live = {
      account_subdomain_name = "cd-live.${local.base_domain}"
    }
  }
}
