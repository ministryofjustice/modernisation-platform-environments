locals {
  test_workload_namespace = "test-workload"
  # HTTPRoute hostnames must be DNS names (no scheme), so trim the provided URL.
  test_workload_hostname = trimsuffix(replace("https://test5.cp-2206-0911.development.container-platform.service.justice.gov.uk", "https://", ""), "/")
}

resource "kubernetes_manifest" "test_workload_namespace" {
	manifest = {
		apiVersion = "v1"
		kind       = "Namespace"
		metadata = {
			name = local.test_workload_namespace
			labels = {
				"pod-security.kubernetes.io/enforce" = "restricted"
			}
		}
	}
}

resource "kubernetes_manifest" "test_workload_deployment" {
	manifest = {
		apiVersion = "apps/v1"
		kind       = "Deployment"
		metadata = {
			name      = "nginx"
			namespace = local.test_workload_namespace
		}
		spec = {
			replicas = 1
			selector = {
				matchLabels = {
					app = "nginx"
				}
			}
			template = {
				metadata = {
					labels = {
						app = "nginx"
					}
				}
				spec = {
					securityContext = {
						seccompProfile = {
							type = "RuntimeDefault"
						}
					}
					containers = [
						{
							name  = "nginx"
							image = "nginxinc/nginx-unprivileged:stable"
							ports = [
								{
									containerPort = 8080
								}
							]
							securityContext = {
								allowPrivilegeEscalation = false
								readOnlyRootFilesystem   = false
								runAsNonRoot             = true
								capabilities = {
									drop = ["ALL"]
								}
							}
						}
					]
				}
			}
		}
	}

  depends_on = [kubernetes_manifest.test_workload_namespace]
}

resource "kubernetes_manifest" "test_workload_service" {
	manifest = {
		apiVersion = "v1"
		kind       = "Service"
		metadata = {
			name      = "nginx"
			namespace = local.test_workload_namespace
		}
		spec = {
			selector = {
				app = "nginx"
			}
			ports = [
				{
					port       = 80
					targetPort = 8080
					protocol   = "TCP"
				}
			]
		}
	}

  depends_on = [kubernetes_manifest.test_workload_deployment]
}

resource "kubernetes_manifest" "test_workload_httproute" {
	manifest = {
		apiVersion = "gateway.networking.k8s.io/v1"
		kind       = "HTTPRoute"
		metadata = {
			name      = "nginx"
			namespace = local.test_workload_namespace
		}
		spec = {
			hostnames = [local.test_workload_hostname]
			parentRefs = [
				{
					name      = "eg"
					namespace = "envoy-gateway-system"
				}
			]
			rules = [
				{
					matches = [
						{
							path = {
								type  = "PathPrefix"
								value = "/"
							}
						}
					]
					backendRefs = [
						{
							name = "nginx"
							port = 80
						}
					]
				}
			]
		}
	}

  depends_on = [
    module.gateway_api,
    kubernetes_manifest.test_workload_service,
  ]
}


resource "kubernetes_manifest" "coraza_waf" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: coraza-waf-httproute
      namespace: test-workload
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: nginx
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              - SecAuditEngine On
              - SecResponseBodyAccess Off
              - Include @crs-setup.conf
              - Include @owasp_crs/*.conf
   YAML
  )
}

