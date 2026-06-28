apiVersion: gateway.networking.k8s.io/v1
kind: ListenerSet
metadata:
  name: ${listenerset_name}
  namespace: ${namespace}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production  
spec:
  parentRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: ${gateway_name}
    namespace: ${namespace}
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.apps.${base_domain}"
      allowedRoutes:
        namespaces:
          from: All
        kinds:
          - group: gateway.networking.k8s.io
            kind: HTTPRoute
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.apps.${base_domain}"
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: ${tls_secret_name}
      allowedRoutes:
        namespaces:
          from: All
        kinds:
          - group: gateway.networking.k8s.io
            kind: HTTPRoute