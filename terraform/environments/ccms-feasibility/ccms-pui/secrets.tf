# PUI application secrets stored as key-value pairs. Values are populated manually after creation.

resource "aws_secretsmanager_secret" "pui" {
  name        = "${local.component_name}-secrets"
  description = "Application secrets for PUI"
}

resource "aws_secretsmanager_secret_version" "pui" {
  secret_id = aws_secretsmanager_secret.pui.id
  secret_string = jsonencode({
    spring_datasource_username                                    = ""
    spring_datasource_password                                    = ""
    spring_datasource_url                                         = ""
    idp_cert                                                      = ""
    spcert                                                        = ""
    spprivatekey                                                  = ""
    idpMetadataUrl                                                = ""
    loginUrl                                                      = ""
    postcodeApiUrl                                                = ""
    postcodeApiKey                                                = ""
    user_management_api_access_token                              = ""
    user_management_api_hostname                                  = ""
    idpIdentityID                                                 = ""
    SpEntityId                                                    = ""
    SpEntityUrl                                                   = ""
    ccms_soa_soapHeaderUserPassword                               = ""
    ccms_soa_soapHeaderUserName                                   = ""
    opa_security_password                                         = ""
    spring_profiles_active                                        = ""
    idpLogoutUrl                                                  = ""
    IdpSamlMockEnabled                                            = ""
    entra_custom_user_id_claim                                    = ""
    is_silas_enabled                                              = ""
    ccms_soa_url_ebsContractDetailsEndpoint                       = ""
    ccms_soa_url_opaBillingAssessmentEndpoint                     = ""
    ccms_soa_url_opaPOAAssessmentEndpoint                         = ""
    ccms_pui_av_port                                              = ""
    ccms_pui_av_socketTimeout                                     = ""
    ccms_pui_av_scannerEnabled                                    = ""
    ccms_pui_auditLogin_enabled                                   = ""
    logging_level_root                                            = ""
    logging_level_com_ezgov                                       = ""
    logging_level_com_legalservices                               = ""
    logging_level_uk_gov_laa_opa                                  = ""
    logging_level_com_ezgov_roof_view_vim_control_BundleAwareText = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
