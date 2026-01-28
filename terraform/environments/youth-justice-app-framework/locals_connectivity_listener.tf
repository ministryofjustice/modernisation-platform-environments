# connectivity_listeners.tf
locals {
  connectivity_listeners = {
    connectivity_listener = {
      port                                 = 8080
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true
      # remove default forward

      rules = {
        connectivity = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-1"
            }
          ]
          conditions = [
            { path_pattern = { values = ["/api/v1/connectivity*", "/cjse/*"] } }
          ]
        },
        connectivity_health = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-1"
            }
          ]
          conditions = [
            { http_header = { http_header_name = "service-health", values = ["connectivity"] } }
          ]
        }
      }
    }
  }
}