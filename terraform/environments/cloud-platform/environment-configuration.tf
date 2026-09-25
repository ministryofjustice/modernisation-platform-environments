locals {
  environment_configurations = {
    cloud-platform-development = {
      account_subdomain_name = "development.${local.base_domain}"
      # Phase-2 gate for the Grafana provider (see local.grafana_objects_enabled).
      #
      # MUST stay false until a phase-1 apply has created the iac-grafana-objects
      # service account (amg.tf). Only then can the pipeline mint a token; only
      # then is it safe to flip this to true so the next apply (phase 2) creates
      # the grafana_* objects. Setting it true before the service account exists
      # reintroduces the bootstrap cycle: Terraform plans the service account and
      # the Grafana objects in one pass, but the provider has no token yet and
      # fails with "missing a configuration for the Grafana API".
      #
      # Sequence for this workspace: (1) apply with false to create the service
      # account, (2) then set true and apply again. Other AMG host workspaces
      # (e.g. cloud-platform-live) follow the same two-step bring-up.
      grafana_objects_enabled = false
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
