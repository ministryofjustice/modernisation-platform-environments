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
  # /cjse* to yjsm-hubadmin on 8401 and /yjs* to yjsm-hub on 9091, but that's
  # a separate, internal entry point, not Juniper's).
  #
  # Juniper always dials port 80 externally regardless of which app answers,
  # so the external listener port below stays 80; only the app behind it
  # changes. yjsm-ui and yjsm-hubadmin stay off the NLB, matching the above.
  yjsm_juniper_facing_apps = {
    yjsm-hub = {
      port = 80
    }
  }

  # Internal-only apps: listeners on the same ALB (ECS needs each service's
  # target group attached to a listener), on the legacy ports, but not
  # fronted by the NLB. ECS callers reach 8401 via rules in modules/ecs; nothing
  # is allowed to 8400 (the UI) yet.
  yjsm_internal_apps = {
    yjsm-ui = {
      port = 8400
    }
    yjsm-hubadmin = {
      port = 8401
    }
  }

  # yjsm-hub serves actuator on a separate management port (9092) because
  # CXF interferes with it on the server port (yjsm-hub application.properties).
  yjsm_hub_health_check = {
    enabled             = true
    interval            = 110
    path                = "/actuator/health"
    port                = "9092"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 100
    protocol            = "HTTP"
    matcher             = "200"
  }

  # yjsm-ui is a static Angular build behind nginx, no actuator.
  yjsm_ui_health_check = {
    enabled             = true
    interval            = 110
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 100
    protocol            = "HTTP"
    matcher             = "200"
  }

  yjsm_apps_listeners = {
    for name, app in merge(local.yjsm_juniper_facing_apps, local.yjsm_internal_apps) : name => {
      port                                 = app.port
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true
      forward = {
        target_group_key = "${name}-target-group-1"
      }
    }
  }
}
