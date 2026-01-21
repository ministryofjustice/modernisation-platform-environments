# Moved blocks to preserve resources when adding count parameter

# Data sources
moved {
  from = data.aws_iam_policy_document.mlflow
  to   = data.aws_iam_policy_document.mlflow[0]
}

# Helm release
moved {
  from = helm_release.mlflow
  to   = helm_release.mlflow[0]
}

# Kubernetes namespace
moved {
  from = kubernetes_namespace.mlflow
  to   = kubernetes_namespace.mlflow[0]
}

# Kubernetes secrets
moved {
  from = kubernetes_secret.mlflow_admin
  to   = kubernetes_secret.mlflow_admin[0]
}

moved {
  from = kubernetes_secret.mlflow_auth_rds
  to   = kubernetes_secret.mlflow_auth_rds[0]
}

moved {
  from = kubernetes_secret.mlflow_flask_server_secret_key
  to   = kubernetes_secret.mlflow_flask_server_secret_key[0]
}

moved {
  from = kubernetes_secret.mlflow_rds
  to   = kubernetes_secret.mlflow_rds[0]
}

# Random passwords
moved {
  from = random_password.mlflow_admin
  to   = random_password.mlflow_admin[0]
}

moved {
  from = random_password.mlflow_auth_rds
  to   = random_password.mlflow_auth_rds[0]
}

moved {
  from = random_password.mlflow_flask_server_secret_key
  to   = random_password.mlflow_flask_server_secret_key[0]
}

moved {
  from = random_password.mlflow_rds
  to   = random_password.mlflow_rds[0]
}

# Modules
moved {
  from = module.mlflow_auth_rds_kms
  to   = module.mlflow_auth_rds_kms[0]
}

moved {
  from = module.mlflow_bucket
  to   = module.mlflow_bucket[0]
}

moved {
  from = module.mlflow_iam_policy
  to   = module.mlflow_iam_policy[0]
}

moved {
  from = module.mlflow_iam_role
  to   = module.mlflow_iam_role[0]
}

moved {
  from = module.mlflow_rds_kms
  to   = module.mlflow_rds_kms[0]
}

moved {
  from = module.mlflow_s3_kms
  to   = module.mlflow_s3_kms[0]
}

moved {
  from = module.rds_security_group
  to   = module.rds_security_group[0]
}

moved {
  from = module.mlflow_auth_rds
  to   = module.mlflow_auth_rds[0]
}

moved {
  from = module.mlflow_rds
  to   = module.mlflow_rds[0]
}
