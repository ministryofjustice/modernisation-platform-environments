locals {
  external_listeners = {
    external_listener = {
      port                                 = 443
      protocol                             = "HTTPS"
      certificate_arn                      = module.certs.domain_cert_arn
      routing_http_response_server_enabled = true
      fixed_response = {
        status_code  = 403
        message_body = "Access Denied"
        content_type = "text/plain"
      }
      rules = {
        gateway = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "gateway-target-group-2"
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
