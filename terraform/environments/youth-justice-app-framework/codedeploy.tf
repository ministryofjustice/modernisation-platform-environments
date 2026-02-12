module "codedeploy" {
  source           = "./modules/codedeploy"
  project_name     = local.project_name
  tags             = local.tags
  cluster_name     = "yjaf-cluster"
  environment      = local.environment
  ec2_enabled      = true
  ec2_applications = ["yjsm-hub", "yjsm-hubadmin", "yjsm-ui"]
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
    { "yjsm-hub-svc" = "yjsm-hub-svc" }
  ]

  internal_alb_name     = "yjaf-int-internal"
  external_alb_name     = "yjaf-ext-external"
  connectivity_alb_name = "yjaf-connectivity-internal"
  yjsm_hub_svc_alb_name = "yjsm-hub-svc-ext"
  depends_on = [
    module.internal_alb,
    module.external_alb,
    module.connectivity_alb,
    module.yjsm_hub_svc_alb,
    module.ecs,
    module.yjsm
  ]
}
