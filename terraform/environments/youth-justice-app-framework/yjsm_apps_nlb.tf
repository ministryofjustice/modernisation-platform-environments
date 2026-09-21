# Internal NLB giving the Juniper device (in its own AWS account, reached
# over Transit Gateway) a fixed private IP to route to, since ECS-backed
# services behind `yjsm_apps_alb` no longer have the stable IP the old yjsm
# EC2 host had. Only fronts yjsm-hub - that's what Juniper's traffic actually
# reaches today (see locals_yjsm_apps.tf); yjsm-ui and yjsm-hub-admin are
# reached via a separate, internal-only path, not by Juniper directly.
module "yjsm_apps_nlb" {
  source = "./modules/nlb"

  environment  = local.environment
  project_name = local.project_name
  vpc_id       = data.aws_vpc.shared.id
  tags         = local.tags

  nlb_name        = "yjaf-yjsm-apps"
  nlb_subnets_ids = local.private_subnet_list[*].id

  # Static IP only in eu-west-2a, the same AZ/subnet the legacy yjsm EC2 host
  # sits in (yjsm.tf) - one +1 above its IP so it doesn't clash. The other
  # AZs' NLB nodes are left to auto-assign since we don't have a reason yet
  # to pin them (the legacy setup was single-AZ too).
  private_ipv4_addresses = {
    for s in local.private_subnet_list : s.id => local.yjsm_apps_nlb_private_ip
    if s.availability_zone == "eu-west-2a"
  }

  target_alb_arn           = module.yjsm_apps_alb.alb_arn
  target_group_name_prefix = "yjaf-nlb"

  # Reuses the same "YJB CUG RANGE 1" managed prefix list that already gates
  # Juniper's traffic to yjsm-hub today (modules/yjsm/security-groups.tf).
  ingress_prefix_list_id = module.yjsm.juniper_cug_prefix_list_id

  apps = {
    for name, app in local.yjsm_juniper_facing_apps : name => {
      listener_port = app.port
      target_port   = app.port
    }
  }

  # alb_arn doesn't depend on the ALB's listeners, and the NLB's "alb" target
  # needs a listener on the target port to exist.
  depends_on = [module.yjsm_apps_alb]
}
