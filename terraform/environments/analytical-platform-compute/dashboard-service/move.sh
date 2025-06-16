#!/bin/bash

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "helm_release.dashboard_service[0]"  "helm_release.dashboard_service[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "kubernetes_manifest.dashboard_service_app_secrets_secret[0]"  "kubernetes_manifest.dashboard_service_app_secrets_secret[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "kubernetes_namespace.dashboard_service[0]"  "kubernetes_namespace.dashboard_service[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "kubernetes_secret.dashboard_service_rds[0]"  "kubernetes_secret.dashboard_service_rds[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "random_password.dashboard_service_rds[0]"  "random_password.dashboard_service_rds[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "random_password.dashboard_service_secret_key[0]"  "random_password.dashboard_service_secret_key[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_app_secrets[0].aws_secretsmanager_secret.this[0]"  "module.dashboard_service_app_secrets[0].aws_secretsmanager_secret.this[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_app_secrets[0].aws_secretsmanager_secret_version.ignore_changes[0]" "module.dashboard_service_app_secrets[0].aws_secretsmanager_secret_version.ignore_changes[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds_kms[0].aws_kms_alias.this[\"rds/dashboard-service\"]" "module.dashboard_service_rds_kms[0].aws_kms_alias.this[\"rds/dashboard-service\"]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds_kms[0].aws_kms_key.this[0]" "module.dashboard_service_rds_kms[0].aws_kms_key.this[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds[0].module.db_instance.aws_db_instance.this[0]" "module.dashboard_service_rds[0].module.db_instance.aws_db_instance.this[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds[0].module.db_instance.aws_iam_role.enhanced_monitoring[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds[0].module.db_instance.aws_iam_role_policy_attachment.enhanced_monitoring[0]"  "module.dashboard_service_rds[0].module.db_instance.aws_iam_role_policy_attachment.enhanced_monitoring[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds[0].module.db_parameter_group.aws_db_parameter_group.this[0]" "module.dashboard_service_rds[0].module.db_parameter_group.aws_db_parameter_group.this[0]" 

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds_kms[0].data.aws_caller_identity.current[0]" "module.dashboard_service_rds_kms[0].data.aws_caller_identity.current[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds_kms[0].data.aws_partition.current[0]" "module.dashboard_service_rds_kms[0].data.aws_partition.current[0]"

terraform state mv -state=../root.tfstate -state-out=dashboard.tfstate "module.dashboard_service_rds[0].module.db_instance.data.aws_partition.current" "module.dashboard_service_rds[0].module.db_instance.data.aws_partition.current"
