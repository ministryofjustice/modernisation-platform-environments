######################################
# PARAMETER STORE SECRETS
######################################
resource "aws_ssm_parameter" "maat_app_cma_oauth_scope" {
  name  = "/maat/APP_CMA_OAUTH_SCOPE"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_bc_client_user_id" {
  name  = "/maat/APP_BC_CLIENT_USER_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccc_endpoint" {
  name  = "/maat/APP_CCC_ENDPOINT"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_orch_oauth_scope" {
  name  = "/maat/APP_ORCH_OAUTH_SCOPE"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccp_client_secret" {
  name  = "/maat/APP_CCP_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_google_analytics_tag_id" {
  name  = "/maat/APP_MAAT_GOOGLE_ANALYTICS_4_TAG_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_cma_client_id" {
  name  = "/maat/APP_CMA_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_cma_client_secret" {
  name  = "/maat/APP_CMA_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_bc_client_orig_id" {
  name  = "/maat/APP_BC_CLIENT_ORIG_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_db_password" {
  name  = "/maat/APP_DB_PASSWORD"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_caa_client_secret" {
  name  = "/maat/APP_CAA_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_orch_client_secret" {
  name  = "/maat/APP_ORCH_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_caa_client_id" {
  name  = "/maat/APP_CAA_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_orch_client_id" {
  name  = "/maat/APP_ORCH_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccc_client_id" {
  name  = "/maat/APP_CCC_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_db_user_id" {
  name  = "/maat/APP_DB_USERID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccc_client_secret" {
  name  = "/maat/APP_CCC_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_orch_endpoint" {
  name  = "/maat/APP_ORCH_ENDPOINT"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccc_oauth_scope" {
  name  = "/maat/APP_CCC_OAUTH_SCOPE"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccp_client_id" {
  name  = "/maat/APP_CCP_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ccp_endpoint_proc" {
  name  = "/maat/APP_CCP_ENDPOINT_PROCEEDINGS"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_caa_endpoint" {
  name  = "/maat/APP_CAA_ENDPOINT"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_bc_service_name" {
  name  = "/maat/APP_BC_SERVICE_NAME"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ats_client_secret" {
  name  = "/maat/APP_ATS_CLIENT_SECRET"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ats_client_id" {
  name  = "/maat/APP_ATS_CLIENT_ID"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_ats_oauth_scope" {
  name  = "/maat/APP_ATS_OAUTH_SCOPE"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}