locals {
  yjsm_hub_svc_listeners = {
    yjsm_hub_svc_listener = {
      port                                 = 443
      protocol                             = "HTTPS"
      certificate_arn                      = module.gateway_certs[0].domain_cert_arn
      routing_http_response_server_enabled = true
      fixed_response = {
        status_code  = 403
        message_body = "Access Denied"
        content_type = "text/plain"
      }
      rules = {
        yjsm-hub-svc = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "yjsm-hub-svc-target-group-1"
            }
          ]
          conditions = [{
            http_header = {
              http_header_name = "X-Custom-Header"
              values           = ["yjaf-cloudfront-custom-2024"]
            }
          }]
        }
      }
    }
  }
}