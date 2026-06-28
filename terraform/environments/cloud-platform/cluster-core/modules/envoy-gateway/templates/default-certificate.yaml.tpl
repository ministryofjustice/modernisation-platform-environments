apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: default
  namespace: ${namespace}
spec:
  secretName: default-certificate
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
    - "*.apps.${cluster_base_domain}"
    - "*.${cluster_base_domain}"