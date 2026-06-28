# # ClientTrafficPolicy to enable HTTP/2 for the Gateway.
# #
# # Without this policy, Envoy Gateway defaults to HTTP/1.1 when multiple HTTPS listeners
# # share the same certificate with overlapping SANs (e.g., *.apps.domain and *.domain).
# # This is a safety measure to prevent HTTP/2 connection coalescing issues.
# #
# # This policy explicitly configures ALPN protocols (h2, http/1.1) to enable HTTP/2
# # while acknowledging the certificate overlap. Consider the implications of HTTP/2
# # connection coalescing when listeners serve different purposes or security boundaries.
# #
# # See: https://gateway-api.sigs.k8s.io/geps/gep-3567/
# resource "kubernetes_manifest" "default_client_traffic_policy" {
#   manifest = {
#     apiVersion = "gateway.envoyproxy.io/v1alpha1"
#     kind       = "ClientTrafficPolicy"

#     metadata = {
#       name      = "default-alpn-policy"
#       namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
#     }

#     spec = {
#       targetRefs = [
#         {
#           group = "gateway.networking.k8s.io"
#           kind  = "Gateway"
#           name  = kubernetes_manifest.gateway.manifest.metadata.name
#         }
#       ]

#       tls = {
#         alpnProtocols = ["h2", "http/1.1"]
#       }
#     }
#   }

#   depends_on = [
#     kubernetes_manifest.gateway
#   ]
# }
