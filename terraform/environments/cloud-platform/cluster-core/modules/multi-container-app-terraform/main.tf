locals {
  # Construct database URL based on whether PostgreSQL is deployed or external
  computed_database_url = var.deploy_postgresql ? (
    "postgresql://${var.postgres_username}:${var.postgres_password}@postgresql.${var.namespace}.svc.cluster.local:5432/${var.postgres_database}"
  ) : var.database_url

  # Use computed URL if create_database_secret is true
  final_database_url = var.create_database_secret ? local.computed_database_url : ""
}

resource "kubectl_manifest" "namespace" {
  yaml_body = templatefile("${path.module}/manifests/namespace.yaml", {
    namespace = var.namespace
  })
  server_side_apply = true
  wait              = true
}

# Optional PostgreSQL deployment
resource "kubectl_manifest" "postgresql_secret" {
  count = var.deploy_postgresql ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/postgresql-secret.yaml", {
    namespace           = var.namespace
    postgres_secret_name = var.postgres_secret_name
    postgres_username   = var.postgres_username
    postgres_password   = var.postgres_password
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "postgresql_deployment" {
  count = var.deploy_postgresql ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/postgresql-deployment.yaml", {
    namespace           = var.namespace
    postgres_secret_name = var.postgres_secret_name
    database_name       = var.postgres_database
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.postgresql_secret
  ]
}

resource "kubectl_manifest" "postgresql_service" {
  count = var.deploy_postgresql ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/postgresql-service.yaml", {
    namespace = var.namespace
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "database_secret" {
  count = var.create_database_secret ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/database-secret.yaml", {
    namespace      = var.namespace
    secret_name    = var.database_secret_name
    database_url   = local.final_database_url
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.postgresql_service
  ]
}

resource "kubectl_manifest" "content_api_deployment" {
  yaml_body = templatefile("${path.module}/manifests/content-api-deployment.yaml", {
    namespace        = var.namespace
    image_repository = var.content_api_image_repository
    image_tag        = var.content_api_image_tag
    replicas         = var.content_api_replicas
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "content_api_service" {
  yaml_body = templatefile("${path.module}/manifests/content-api-service.yaml", {
    namespace = var.namespace
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "rails_app_deployment" {
  yaml_body = templatefile("${path.module}/manifests/rails-app-deployment.yaml", {
    namespace               = var.namespace
    image_repository        = var.rails_app_image_repository
    image_tag               = var.rails_app_image_tag
    replicas                = var.rails_app_replicas
    database_secret_name    = var.database_secret_name
    content_api_url         = var.content_api_url
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.database_secret
  ]
}

resource "kubectl_manifest" "rails_app_service" {
  yaml_body = templatefile("${path.module}/manifests/rails-app-service.yaml", {
    namespace = var.namespace
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace
  ]
}

resource "kubectl_manifest" "worker_deployment" {
  yaml_body = templatefile("${path.module}/manifests/worker-deployment.yaml", {
    namespace            = var.namespace
    image_repository     = var.worker_image_repository
    image_tag            = var.worker_image_tag
    replicas             = var.worker_replicas
    database_secret_name = var.database_secret_name
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.database_secret
  ]
}

resource "kubectl_manifest" "rails_migrations_job" {
  count = var.enable_migrations ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/migrations-job.yaml", {
    namespace            = var.namespace
    image_repository     = var.rails_app_image_repository
    image_tag            = var.rails_app_image_tag
    database_secret_name = var.database_secret_name
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.database_secret
  ]
}

resource "kubectl_manifest" "http_route" {
  count = var.enable_httproute ? 1 : 0

  yaml_body = templatefile("${path.module}/manifests/http-route.yaml", {
    namespace             = var.namespace
    listenerset_name      = var.listenerset_name
    listenerset_namespace = var.listenerset_namespace
    hostnames             = var.hostnames
  })
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.rails_app_service
  ]
}
