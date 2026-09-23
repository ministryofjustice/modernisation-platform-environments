locals {
  environment_configurations = {
    cloud-platform-development = {
      account_subdomain_name = "development.${local.base_domain}"
      # Phase-2 gate for the Grafana provider (see local.grafana_objects_enabled).
      # Set true only after a phase-1 apply has created the iac-grafana-objects
      # service account, so the pipeline can mint a token. On a brand-new AMG
      # workspace this must start false (or be omitted) for the first apply, then
      # be flipped to true. Other AMG host workspaces (e.g. cloud-platform-live)
      # add this key the same way when they are first brought up.
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
