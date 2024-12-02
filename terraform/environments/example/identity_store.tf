###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################

# data "aws_ssoadmin_instances" "example" {
#   provider = aws.sso-readonly
# }

# data "aws_identitystore_group" "example" {
#   provider          = aws.sso-readonly
#   identity_store_id = tolist(data.aws_ssoadmin_instances.example.identity_store_ids)[0]

#   filter {
#     attribute_path  = "DisplayName"
#     attribute_value = "modernisation-platform"
#   }
# }