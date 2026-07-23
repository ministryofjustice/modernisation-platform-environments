resource "aws_secretsmanager_secret" "oia" {
  name        = local.component_name
  description = "Shared credentials for the ${local.component_name} component"
}

resource "aws_secretsmanager_secret_version" "oia" {
  secret_id = aws_secretsmanager_secret.oia.id
  secret_string = jsonencode({
    guardduty_slack_channel_id      = ""
    cloudwatch_slack_channel_id     = ""
    slack_channel_webhook           = ""
    slack_channel_webhook_guardduty = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "oia" {
  secret_id = aws_secretsmanager_secret.oia.id
}

resource "aws_secretsmanager_secret" "opahub" {
  name        = local.opahub_name
  description = "OPAHub Application Secrets"
}

resource "aws_secretsmanager_secret_version" "opahub" {
  secret_id = aws_secretsmanager_secret.opahub.id
  secret_string = jsonencode({
    opahub_password = ""
    db_user         = ""
    db_password     = ""
    wl_user         = ""
    wl_password     = ""
    secret_key      = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "opahub" {
  secret_id = aws_secretsmanager_secret.opahub.id
}

resource "aws_secretsmanager_secret" "connector" {
  name        = local.connector_name
  description = "Connector Application Secrets"
}

resource "aws_secretsmanager_secret_version" "connector" {
  secret_id = aws_secretsmanager_secret.connector.id
  secret_string = jsonencode({
    ccms_soa_soapHeaderUserName               = ""
    ccms_soa_soapHeaderUserPassword           = ""
    ccms_connector_service_userid             = ""
    ccms_connector_service_password           = ""
    client_opa12assess_security_user_name     = ""
    client_opa12assess_security_user_password = ""
    spring_datasource_url                     = ""
    spring_datasource_username                = ""
    spring_datasource_password                = ""
    opa_security_password                     = ""
    ccms_bc_url                               = ""
    ccms_bc_lscServiceName                    = ""
    ccms_bc_clientOrgId                       = ""
    ccms_bc_clientUserId                      = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "connector" {
  secret_id = aws_secretsmanager_secret.connector.id
}

resource "aws_secretsmanager_secret" "adaptor" {
  name        = local.adaptor_name
  description = "Service Adaptor Application Secrets"
}

resource "aws_secretsmanager_secret_version" "adaptor" {
  secret_id = aws_secretsmanager_secret.adaptor.id
  secret_string = jsonencode({
    client_opa12assess_security_user_name     = ""
    client_opa12assess_security_user_password = ""
    server_opa10assess_security_user_name     = ""
    server_opa10assess_security_user_password = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "adaptor" {
  secret_id = aws_secretsmanager_secret.adaptor.id
}
