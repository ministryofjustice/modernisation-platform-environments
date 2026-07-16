# module "multi_container_app" {
#   source = "./modules/multi-container-app-terraform"

#   # Basic configuration
#   namespace = "my-multi-container-app"

#   # Option 1: Deploy PostgreSQL with the app (like Helm chart)
#   deploy_postgresql    = true
#   postgres_database    = "my_app_db"
#   postgres_username    = "appuser"
#   postgres_password    = "secure-password-here"
  
#   # The database secret is created automatically
#   create_database_secret = true

#   # Optional: Scale replicas
#   content_api_replicas = 2
#   rails_app_replicas   = 3
#   worker_replicas      = 1

#   # Optional: Use different image versions
#   content_api_image_tag = "content-api-1.6"
#   rails_app_image_tag   = "rails-app-1.6"
#   worker_image_tag      = "worker-1.6"

#   # Optional: Enable external access via HTTPRoute
#   enable_httproute = true
#   hostnames = [
#     "my-multi-container-app.${local.cluster_domain}"
#   ]

#   # Optional: Disable migrations if not needed
#   enable_migrations = true
# }