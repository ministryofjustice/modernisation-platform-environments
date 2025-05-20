# ######################################
# # PARAMETER STORE SECRETS
# ######################################
# resource "aws_ssm_parameter" "data_source_username" {
#   name  = "/maat-cd-api/DATASOURCE_USERNAME"
#   type  = "SecureString"
#   value = "replace in console"
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }

# resource "aws_ssm_parameter" "data_source_password" {
#   name  = "APP_MAATDB_DBPASSWORD_MLA1"
#   type  = "SecureString"
#   value = "replace in console"
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }

# resource "aws_ssm_parameter" "cda_client_id" {
#   name  = "/maat-cd-api/CDA_OAUTH_CLIENT_ID"
#   type  = "SecureString"
#   value = "replace in console"
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }

# resource "aws_ssm_parameter" "cda_client_secret" {
#   name  = "/maat-cd-api/CDA_OAUTH_CLIENT_SECRET"
#   type  = "SecureString"
#   value = "replace in console"
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }

# resource "aws_ssm_parameter" "togdata_datasource_password" {
#   name  = "APP_MAATDB_DBPASSWORD_TOGDATA"
#   type  = "SecureString"
#   value = "replace in console"
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }