# SECRET_LDAP_BIND_PASSWORD="password"
# SECRET_LDAP_ADMIN_PASSWORD="password"
# SECRET_oasys_user="oasys"
# SECRET_oasys_password="password"
# SECRET_iaps_user="iaps"
# SECRET_iaps_user_password="password"
# SECRET_dss_user="dss"
# SECRET_dss_user_password="password"
# SECRET_casenotes_user="casenotes"
# SECRET_casenotes_user_password="password"
# SECRET_test_user_password="password"
# SECRET_/delius-core-dev/delius-core/gdpr/api/client_secret="password"
# SECRET_/delius-core-dev/delius-core/pwm/pwm/config_password="password"
# SECRET_/delius-core-dev/delius-core/merge/api/client_secret="secret"
# SECRET_/delius-core-dev/delius-core/weblogic/ndelius-domain/umt_client_secret="secret"

resource "aws_ssm_parameter" "ldap_bind_password" {
  name  = format("/%s-%s/LDAP_BIND_PASSWORD", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "ldap_admin_password" {
  name  = format("/%s-%s/LDAP_ADMIN_PASSWORD", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "oasys_user" {
  name  = format("/%s-%s/oasys_user", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "oasys_password" {
  name  = format("/%s-%s/oasys_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "iaps_user" {
  name  = format("/%s-%s/iaps_user", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "iaps_user_password" {
  name  = format("/%s-%s/iaps_user_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "dss_user" {
  name  = format("/%s-%s/dss_user", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "dss_user_password" {
  name  = format("/%s-%s/dss_user_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "casenotes_user" {
  name  = format("/%s-%s/casenotes_user", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags

}

resource "aws_ssm_parameter" "casenotes_user_password" {
  name  = format("/%s-%s/casenotes_user_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "test_user_password" {
  name  = format("/%s-%s/test_user_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "performance_test_user_password" {
  name  = format("/%s-%s/performance_test_user_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_gdpr_api_client_secret" {
  name  = format("/%s-%s/gdpr_api_client_secret", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_pwm_config_password" {
  name  = format("/%s-%s/pwm_config_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_merge_api_client_secret" {
  name  = format("/%s-%s/merge_api_client_secret", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

data "aws_ssm_parameter" "delius_core_merge_api_client_secret" {
  name = aws_ssm_parameter.delius_core_merge_api_client_secret.name
}

resource "aws_ssm_parameter" "delius_core_weblogic_ndelius_domain_umt_client_secret" {
  name  = format("/%s-%s/umt_client_secret", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_gdpr_db_admin_password" {
  name  = format("/%s-%s/gdpr/api/db_admin_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_gdpr_db_pool_password" {
  name  = format("/%s-%s/gdpr/api/db_pool_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_merge_db_admin_password" {
  name  = format("/%s-%s/merge/api/db_admin_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_merge_db_pool_password" {
  name  = format("/%s-%s/merge/api/db_pool_password", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}


######################################
# S3 Bucket for ssm session manager
######################################
module "s3_bucket_ssm_sessions" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_prefix      = "${var.env_name}-ssm-sessions"
  versioning_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  tags = var.tags
}
