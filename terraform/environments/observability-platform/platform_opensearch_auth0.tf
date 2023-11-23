### AWS Opensearch SAML -- client, rule, metadata and configure opensearch
resource "aws_opensearch_domain_saml_options" "logs" {
  domain_name = aws_opensearch_domain.logs.domain_name
  saml_options {
    enabled = true

    idp {
      entity_id        = "urn:${var.auth0_tenant_domain}"
      metadata_content = data.http.saml_metadata_logs.response_body
    }

    master_backend_role = aws_iam_role.os_access_role_logs.arn
    master_user_name    = aws_iam_role.os_access_role_logs.arn
    roles_key           = "http://schemas.xmlsoap.org/claims/Group"
  }
}


resource "auth0_client" "opensearch_logs" {
  name                       = "AWS Opensearch SAML for observability platform for user app logs"
  description                = "Github SAML provider for observability platform for application logs"
  app_type                   = "spa"
  custom_login_page_on       = true
  is_first_party             = true
  token_endpoint_auth_method = "none"

  // TODO: restore vanity url
  # callbacks = ["https://${aws_route53_record.opensearch_custom_domain.fqdn}/_dashboards/_opendistro/_security/saml/acs"]
  callbacks = ["https://${aws_opensearch_domain.logs.endpoint}/_dashboards/_opendistro/_security/saml/acs"]
  logo_uri  = "https://ministryofjustice.github.io/assets/moj-crest.png"
  addons {
    samlp {
      audience    = "https://${aws_opensearch_domain.logs.endpoint}"
      destination = "https://${aws_opensearch_domain.logs.endpoint}/_dashboards/_opendistro/_security/saml/acs"
      # audience    = "https://${aws_route53_record.opensearch_custom_domain.fqdn}"
      # destination = "https://${aws_route53_record.opensearch_custom_domain.fqdn}/_dashboards/_opendistro/_security/saml/acs"
      mappings = {
        email  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
        name   = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
        groups = "http://schemas.xmlsoap.org/claims/Group"
      }
      include_attribute_name_format      = false
      create_upn_claim                   = false
      passthrough_claims_with_no_mapping = false
      map_unknown_claims_as_is           = false
      map_identities                     = false
      name_identifier_format             = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
      name_identifier_probes             = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
      lifetime_in_seconds                = 36000
    }
  }
}

resource "auth0_rule" "add-github-teams-to-opensearch-saml" {
  name = "add-github-teams-to-os-saml-observability-plat"
  script = file(
    "${path.module}/resources/auth0-rules/add-github-teams-to-opensearch-saml.js",
  )
  order   = 40
  enabled = true
}

resource "auth0_rule_config" "opensearch_logs_client_id" {
  key   = "OPENSEARCH_APP_CLIENT_ID"
  value = auth0_client.opensearch_logs.client_id
}

