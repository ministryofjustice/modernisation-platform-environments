apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: ${gateway_name}-envoy-proxy
  namespace: ${namespace}
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyDeployment:
        replicas: ${envoy_proxy_replicas}
      envoyService:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-name: ${cluster_name}-envoy-${gateway_name}
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: TCP
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: traffic-port
          service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
