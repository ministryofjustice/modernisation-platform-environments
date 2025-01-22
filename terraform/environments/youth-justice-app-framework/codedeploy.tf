
module "codedeploy" {
  source       = "./modules/codedeploy"
  project_name = local.project_name
  tags         = local.tags
  cluster_name = "yjaf-cluster"
  environment  = local.environment
  services = [
    { "auth" = "internal" },
    { "bands" = "internal" },
    { "bu" = "internal" },
    { "case" = "internal" },
    { "cmm" = "internal" },
    { "conversions" = "internal" },
    { "dal" = "internal" },
    { "documents" = "internal" },
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
  ]

  internal_alb_name = "yjaf-int-internal"
  external_alb_name = "yjaf-ext-external"
  depends_on = [
    module.internal_alb,
    module.external_alb,
    module.ecs
  ]
}
