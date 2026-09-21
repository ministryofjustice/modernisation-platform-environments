module "codedeploy" {
  source           = "./modules/codedeploy"
  create_svc_pilot = local.application_data.accounts[local.environment].create_svc_pilot # Added to conditionally create resources for the service pilot
  project_name     = local.project_name
  tags             = local.tags
  cluster_name     = "yjaf-cluster"
  environment      = local.environment
  services = [
    { "auth" = "internal" },
    { "assets" = "internal" },
    { "bands" = "internal" },
    { "bu" = "internal" },
    { "case" = "internal" },
    { "cmm" = "internal" },
    { "connectivity" = "connectivity" },
    { "conversions" = "internal" },
    { "dal" = "internal" },
    { "documents" = "internal" },
    { "gateway-internal" = "internal" },
    { "gateway-external" = "external" },
    { "placements" = "internal" },
    { "refdata" = "internal" },
    { "returns" = "internal" },
    { "sentences" = "internal" },
    { "serious-incidents" = "internal" },
    { "transfers" = "internal" },
    { "transitions" = "internal" },
    { "ui" = "internal" },
    { "views" = "internal" },
    { "workflow" = "internal" },
    { "yp" = "internal" },
    { "yjsm-hub-svc" = "yjsm-hub-svc" },
    { "yjsm-hub" = "yjsm-hub" },
    { "yjsm-hubadmin" = "yjsm-hubadmin" },
    { "yjsm-ui" = "yjsm-ui" }
  ]

  internal_alb_name     = "yjaf-int-internal"
  external_alb_name     = "yjaf-ext-external"
  connectivity_alb_name = "yjaf-connectivity-internal"
  yjsm_hub_svc_alb_name = "yjsm-hub-svc-ext-external"
  yjsm_apps_alb_name    = "yjaf-yjsm-apps-internal"
  # each yjsm app has its own listener on the yjsm apps ALB
  yjsm_apps_listener_ports = { for name, app in merge(local.yjsm_juniper_facing_apps, local.yjsm_internal_apps) : name => app.port }
  depends_on = [
    module.internal_alb,
    module.external_alb,
    module.connectivity_alb,
    module.yjsm_hub_svc_alb,
    module.yjsm_apps_alb,
    module.ecs
  ]
}
