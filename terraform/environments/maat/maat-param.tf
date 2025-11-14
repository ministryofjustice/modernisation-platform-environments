######################################
# PARAMETER STORE SECRETS
######################################
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

resource "aws_ssm_parameter" "maat_app_master_password" {
  name  = "/maat/APP_MASTER_PASSWORD"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_salt" {
  name  = "/maat/APP_SALT"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "maat_app_derivation_iterations" {
  name  = "/maat/APP_DERIVATION_ITERATIONS"
  type  = "SecureString"
  value = "replace in console"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}