locals {
  # Helper to resolve the target group ARN, whether local or existing
  connectivity_tg_arn = lookup(
    var.existing_target_groups,
    "connectivity-target-group-1",
    aws_lb_target_group.this["connectivity-target-group-1"].arn
  )

  connectivity_listeners = {
    connectivity_listener = {
      port                                 = 8080
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true

      # Default forward uses helper
      forward = {
        target_group_arn = local.connectivity_tg_arn
      }

      rules = {
        connectivity = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_arn = local.connectivity_tg_arn
            }
          ]
          conditions = [
            {
              path_pattern = {
                values = ["/api/v1/connectivity*", "/cjse/*"]
              }
            }
          ]
        },

        connectivity_health = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_arn = local.connectivity_tg_arn
            }
          ]
          conditions = [
            {
              http_header = {
                http_header_name = "service-health"
                values           = ["connectivity"]
              }
            }
          ]
        }
      }
    }
  }
}