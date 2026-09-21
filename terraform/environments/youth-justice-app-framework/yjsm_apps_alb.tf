# Dedicated internal ALB for the yjsm apps moving into the ECS cluster.
# Kept separate from `internal_alb` (which fronts every other microservice on
# one shared listener) so this Juniper integration has its own security
# group and listener surface, the same isolation `connectivity_alb` and
# `yjsm_hub_svc_alb` give their own integrations.
#tfsec:ignore:AWS0054 "This is an internal alb, traffic only arrives via Transit Gateway from Juniper's AWS account and https is not required."
#tfsec:ignore:AVD-AWS-0054
module "yjsm_apps_alb" {
  source = "./modules/alb"
  #pass in provider for creating records on central route53
  providers = {
    aws.core-network-services = aws.core-network-services
  }

  environment     = local.environment
  project_name    = local.project_name
  vpc_id          = data.aws_vpc.shared.id
  alb_subnets_ids = local.private_subnet_list[*].id
  tags            = local.tags

  alb_name = "yjaf-yjsm-apps"
  internal = true

  listeners              = local.yjsm_apps_listeners
  existing_target_groups = module.internal_alb.target_group_arns

  # Juniper (via the NLB) reaches the hub listener through the prefix list below;
  # ECS callers get their own rules in modules/ecs. Reuses the same managed prefix list
  # ("YJB CUG RANGE 1") that already gates Juniper's traffic to yjsm-hub today
  # (modules/yjsm/security-groups.tf; see locals_yjsm_apps.tf for how we
  # confirmed it's yjsm-hub, not yjsm-ui), since it's the same network.
  alb_ingress_prefix_list_ids = [module.yjsm.juniper_cug_prefix_list_id]

  alb_ingress_with_prefix_list_ids_rules = [
    for name, app in local.yjsm_juniper_facing_apps : {
      from_port   = tostring(app.port)
      to_port     = tostring(app.port)
      protocol    = "tcp"
      description = "Juniper (YJB CUG range, via Transit Gateway, through the yjsm apps NLB) to yjsm apps ALB (${name})"
    }
  ]

  enable_access_logs = true
}
