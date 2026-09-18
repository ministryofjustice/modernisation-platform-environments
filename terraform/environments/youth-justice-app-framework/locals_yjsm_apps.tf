locals {
  # Only yjsm-ui is reached by Juniper - confirmed against the existing EC2
  # setup, where only port 80 has a CIDR/prefix-list rule
  # (modules/yjsm/security-groups.tf). yjsm-hub and yjsm-hub-admin are
  # internal-only dependencies of yjsm-ui (reached via nginx today) and are
  # not exposed on yjsm_apps_alb / yjsm_apps_nlb. Their target groups still
  # exist in locals_target_groups.tf for whatever internal routing ECS ends
  # up using, they're just not wired into a listener here yet.
  yjsm_juniper_facing_apps = {
    yjsm-ui = {
      port = 80
    }
  }

  yjsm_apps_listeners = {
    for name, app in local.yjsm_juniper_facing_apps : name => {
      port                                 = app.port
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true
      forward = {
        target_group_key = "${name}-target-group-1"
      }
    }
  }

  # Static private IP for the yjsm apps NLB, one +1 above the existing yjsm
  # EC2 host's IP (yjsm.tf) in the same subnet (eu-west-2a) so it doesn't
  # clash with it. TODO(OPS-1202): sanity-check these are actually free
  # before apply - Terraform/AWS will only catch a clash at apply time.
  yjsm_apps_nlb_private_ip = lookup(
    {
      development   = "10.26.144.62"
      test          = "10.26.152.173"
      preproduction = "10.27.144.84"
      production    = "10.27.152.22"
    },
    local.environment,
    null
  )
}
