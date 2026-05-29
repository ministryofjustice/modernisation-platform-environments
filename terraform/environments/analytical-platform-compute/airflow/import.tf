# This file is used to import the existing k8s reesources and iam polcies into Terraform state.Will be deleted after the import is complete and the state file is updated.

#### NAMESPACES ######
# airflow namespace
import {
  to = kubernetes_namespace_v1.airflow
  id = "airflow"
}

removed {
  from = kubernetes_namespace.airflow
  lifecycle {
    destroy = false
  }
}

# mwaa namespace
import {
  to = kubernetes_namespace_v1.mwaa
  id = "mwaa"
}

removed {
  from = kubernetes_namespace.mwaa
  lifecycle {
    destroy = false
  }
}


###### ROLES #######
#kubernetes_role_v1 airflow_execution
import {
  to = kubernetes_role_v1.airflow_execution
  id = "airflow/airflow-execution"
}

removed {
  from = kubernetes_role.airflow_execution
  lifecycle {
    destroy = false
  }
}

#kubernetes_role_v1 airflow_serviceaccount_management
import {
  to = kubernetes_role_v1.airflow_serviceaccount_management
  id = "airflow/airflow-serviceaccount-management"
}

removed {
  from = kubernetes_role.airflow_serviceaccount_management
  lifecycle {
    destroy = false
  }
}

#kubernetes_role_v1 mwaa_execution
import {
  to = kubernetes_role_v1.mwaa_execution
  id = "mwaa/mwaa-execution"
}

removed {
  from = kubernetes_role.mwaa_execution
  lifecycle {
    destroy = false
  }
}

#kubernetes_role_v1 mwaa_serviceaccount_management
import {
  to = kubernetes_role_v1.mwaa_serviceaccount_management
  id = "mwaa/mwaa-serviceaccount-management"
}

removed {
  from = kubernetes_role.mwaa_serviceaccount_management
  lifecycle {
    destroy = false
  }
}

#kubernetes_role_v1 mwaa_external_secrets
import {
  to = kubernetes_role_v1.mwaa_external_secrets
  id = "mwaa/mwaa-external-secrets"
}

removed {
  from = kubernetes_role.mwaa_external_secrets
  lifecycle {
    destroy = false
  }
}



#### ROLE BINDINGS ######
# kubernetes_role_binding - airflow_execution
import {
  to = kubernetes_role_binding_v1.airflow_execution
  id = "airflow/airflow-execution"
}

removed {
  from = kubernetes_role_binding.airflow_execution
  lifecycle {
    destroy = false
  }
}

# kubernetes_role_binding - airflow_serviceaccount_management
import {
  to = kubernetes_role_binding_v1.airflow_serviceaccount_management
  id = "airflow/airflow-serviceaccount-management"
}

removed {
  from = kubernetes_role_binding.airflow_serviceaccount_management
  lifecycle {
    destroy = false
  }
}

# kubernetes_role_binding - mwaa_execution
import {
  to = kubernetes_role_binding_v1.mwaa_execution
  id = "mwaa/mwaa-execution"
}

removed {
  from = kubernetes_role_binding.mwaa_execution
  lifecycle {
    destroy = false
  }
}

# kubernetes_role_binding - mwaa_serviceaccount_management
import {
  to = kubernetes_role_binding_v1.mwaa_serviceaccount_management
  id = "mwaa/mwaa-serviceaccount-management"
}

removed {
  from = kubernetes_role_binding.mwaa_serviceaccount_management
  lifecycle {
    destroy = false
  }
}
# kubernetes_role_binding - mwaa_external_secrets
import {
  to = kubernetes_role_binding_v1.mwaa_external_secrets
  id = "mwaa/mwaa-external-secrets"
}
removed {
  from = kubernetes_role_binding.mwaa_external_secrets
  lifecycle {
    destroy = false
  }
}



### Service Account ###
#kubernetes_service_account - mwaa_external_secrets_analytical_platform_data_production
import {
  to = kubernetes_service_account_v1.mwaa_external_secrets_analytical_platform_data_production
  id = "mwaa/external-secrets-analytical-platform-data-production"
}

removed {
  from = kubernetes_service_account.mwaa_external_secrets_analytical_platform_data_production
  lifecycle {
    destroy = false
  }
}



# moved block for mwaa policy attachment v5 to v6 upgrade
moved {
  from = module.mwaa_ses_iam_user.aws_iam_user_policy_attachment.this["0"]
  to   = module.mwaa_ses_iam_user.aws_iam_user_policy_attachment.additional["mwaa_ses_policy"]
}

moved {
  from = module.mwaa_execution_iam_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.mwaa_execution_iam_role.aws_iam_role_policy_attachment.this["mwaa_execution_policy"]
}
