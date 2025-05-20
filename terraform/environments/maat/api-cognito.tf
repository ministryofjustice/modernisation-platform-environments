# ######################################
# # MAAT API COGNITO USER POOL
# ######################################

# resource "aws_cognito_user_pool" "maat_api_cognito_user_pool" {
#   name = "${local.application_name}-cd-api-UserPool"

#   admin_create_user_config {
#     allow_admin_create_user_only = true
#   }
# }


# ######################################
# # MAAT API COGNITO USER POOL DOMAIN
# ######################################

# resource "aws_cognito_user_pool_domain" "maat_api_cognito_user_pool_domain" {
#   user_pool_id = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   domain       = "${local.application_name}-cd-api-${local.application_data.accounts[local.environment].env_short_name}-mp"
# }


# ######################################
# # MAAT API COGNITO USER POOL SERVER
# ######################################

# resource "aws_cognito_resource_server" "maat_api_cognito_user_pool_server" {
#   user_pool_id = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   identifier   = "${local.application_name}-cd-api"
#   name         = "${local.application_name}-cd-api-ResourceServer1"

#   scope {
#     scope_name        = local.application_data.accounts[local.environment].maat_api_api_scope
#     scope_description = "${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"
#   }
# }


# ######################################
# # MAAT API COGNITO USER POOL CLIENTS
# ######################################

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_default" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "DEFAULT"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_cda" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "CDA"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_cma" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crime Means Assessment"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_ccp" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crown Court Proceeding"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_ccc" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crown Court Contribution"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_ce" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crime Evidence"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_caa" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crime Apply Adapter"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_ats" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Application Tracking Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_dcrs" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "DCES Debt collection Report Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_dirs" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "DCES DRC Integration Report Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_chs" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crime Hardship Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_cvs" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Crime Validation Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_maatos" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "MAAT Orchestration Service"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

# resource "aws_cognito_user_pool_client" "maat_api_cognito_pool_client_cccd" {
#   depends_on = [aws_cognito_resource_server.maat_api_cognito_user_pool_server]

#   name                                 = "Claim for Crown Court Defence"
#   user_pool_id                         = aws_cognito_user_pool.maat_api_cognito_user_pool.id
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   supported_identity_providers         = ["COGNITO"]
#   allowed_oauth_flows                  = ["client_credentials"]
#   allowed_oauth_scopes                 = ["${local.application_name}-cd-api/${local.application_data.accounts[local.environment].maat_api_api_scope}"]
#   prevent_user_existence_errors        = "ENABLED"
#   explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
# }

