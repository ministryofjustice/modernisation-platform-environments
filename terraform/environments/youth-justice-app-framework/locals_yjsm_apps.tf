locals {
  # Confirmed against yjsm-nginx-configs/{Production,Test}/nginx.conf: the
  # primary/CUG-gated IP (the one with the prefix-list rule on port 80,
  # modules/yjsm/security-groups.tf) has an nginx server block that catches
  # everything and proxies straight to yjsm-hub on 127.0.0.1:9091. So Juniper
  # actually talks to yjsm-hub, not yjsm-ui.
  #
  # yjsm-ui is served by a *different* nginx server block, bound to the
  # secondary private IP on port 8400 - a port/IP combo the CUG prefix list
  # doesn't cover at all, so it's internal-only (nginx there also proxies
  # /cjse* to yjsm-hub-admin on 8401 and /yjs* to yjsm-hub on 9091, but that's
  # a separate, internal entry point, not Juniper's).
  #
  # Juniper always dials port 80 externally regardless of which app answers,
  # so the external listener port below stays 80; only the app behind it
  # changes. yjsm-hub-admin stays excluded, matching the above.
  yjsm_juniper_facing_apps = {
    yjsm-hub = {
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
