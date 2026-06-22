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


resource "kubernetes_manifest" "coraza_waf_http" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: coraza-waf
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
              # Loads Coraza base defaults and recommended core settings.
              - Include @coraza.conf

              # Enforces the WAF engine to be active and process requests/responses.
              - SecRuleEngine On

              # Enables audit logging for matched/security-relevant transactions.
              - SecAuditEngine On

              # Writes audit logs as JSON to make stern/k9s output machine-parseable.
              - SecAuditLogFormat JSON

              # Sends audit logs to container stdout so they appear in Kubernetes logs.
              - SecAuditLog /dev/stdout

              # Skips response body inspection to reduce overhead/noise.
              - SecResponseBodyAccess Off

              # Loads CRS tuning/bootstrap variables before CRS rules.
              - Include @crs-setup.conf

              # Loads the full OWASP Core Rule Set.
              - Include @owasp_crs/*.conf
   YAML
  )
}
