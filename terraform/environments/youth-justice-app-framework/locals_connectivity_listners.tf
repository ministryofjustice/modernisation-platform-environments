locals {
  connectivity_listeners = {
    connectivity_listener = {
      port                                 = 8080
      protocol                             = "HTTP"
      routing_http_response_server_enabled = true
      forward = {
        target_group_key = "connectivity-target-group-1"
      }
      rules = {
        connectivity = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-1"
            }
          ]
          conditions = [{
            path_pattern = {
              values = ["/ui", "/api/v1/ui*"]
            }
          }]
        },
        connectivity_health = {
          priority = 23
          actions = [
            {
              type             = "forward"
              target_group_key = "connectivity-target-group-1"
            }
          ]
          conditions = [{ #header condition for connectivity health check
            http_header = {
              http_header_name = "service-health"
              values           = ["connectivity"]
            }
          }]
        }
      }
    }
  } 
}