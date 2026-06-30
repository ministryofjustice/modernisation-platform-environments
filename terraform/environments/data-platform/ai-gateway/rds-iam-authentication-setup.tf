# ──────────────────────────────────────────────────────────────────
# Grant rds_iam role to the litellm DB user (one-time setup).
# Runs after the namespace and Aurora cluster exist,
# and before the Helm releases deploy.
# The master password is mounted from a short-lived k8s secret
# rather than passed inline, to avoid exposure in pod specs
# and the process list.
# ──────────────────────────────────────────────────────────────────
resource "kubernetes_secret_v1" "psql_temp" {
  metadata {
    name      = "psql-temp"
    namespace = local.component_name
  }
  data = {
    password = random_password.aurora.result
  }
  depends_on = [
    module.ai_gateway_namespace,
    module.ai_gateway_aurora
  ]
}

resource "null_resource" "grant_rds_iam" {
  provisioner "local-exec" {
    command = <<-EOT
      cat > /tmp/psql-grant.yaml << 'MANIFEST'
      apiVersion: v1
      kind: Pod
      metadata:
        name: psql-grant
        namespace: ${local.component_name}
      spec:
        restartPolicy: Never
        serviceAccountName: ${local.component_name}
        tolerations:
        - key: "compute.data-platform.service.justice.gov.uk/node-pool"
          operator: "Exists"
          effect: "NoSchedule"
        securityContext:
          runAsNonRoot: true
          seccompProfile:
            type: RuntimeDefault
        volumes:
        - name: psql-temp
          secret:
            secretName: psql-temp
        containers:
        - name: psql
          image: postgres:15-alpine
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 65534
            capabilities:
              drop:
              - ALL
          command:
          - sh
          - -c
          - |
            wget -qO /tmp/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
            PGPASSWORD="$(cat /var/secrets/password)" psql \
              "host=${module.ai_gateway_aurora.cluster_endpoint} \
               port=${tostring(module.ai_gateway_aurora.cluster_port)} \
               dbname=${module.ai_gateway_aurora.cluster_database_name} \
               user=${module.ai_gateway_aurora.cluster_master_username} \
               sslmode=verify-full \
               sslrootcert=/tmp/global-bundle.pem" \
              -c "GRANT rds_iam TO ${module.ai_gateway_aurora.cluster_master_username};"
          volumeMounts:
          - name: psql-temp
            mountPath: /var/secrets
            readOnly: true
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
      MANIFEST
      kubectl delete pod psql-grant -n ${local.component_name} --ignore-not-found
      kubectl apply -f /tmp/psql-grant.yaml
      kubectl wait pod psql-grant -n ${local.component_name} \
        --for=jsonpath='{.status.phase}'=Succeeded --timeout=120s
      kubectl describe pod psql-grant -n ${local.component_name}
      kubectl logs psql-grant -n ${local.component_name} --all-containers=true
    EOT
  }
  depends_on = [
    module.ai_gateway_namespace,
    kubernetes_service_account_v1.ai_gateway,
    kubernetes_secret_v1.psql_temp
  ]
}

resource "null_resource" "cleanup_psql_temp" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl delete pod psql-grant -n ${local.component_name} --ignore-not-found
      kubectl delete secret psql-temp -n ${local.component_name} --ignore-not-found
    EOT
  }
  depends_on = [null_resource.grant_rds_iam]
}