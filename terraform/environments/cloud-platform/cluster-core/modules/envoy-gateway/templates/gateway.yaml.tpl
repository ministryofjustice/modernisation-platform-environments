apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ${gateway_name}
  namespace: ${namespace}
spec:
  gatewayClassName: ${gateway_class_name}
  listeners:
    - name: platform-http
      protocol: HTTP
      port: 80
    # - name: platform-tls
    #   protocol: TLS
    #   port: 443
    #   tls:
    #     mode: Passthrough
  # Any namespace can attach a ListenerSet to this platform Gateway.
  allowedListeners:
    namespaces:
      from: All
