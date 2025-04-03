# module "transfer_service_analytical_platform_topic" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   source  = "terraform-aws-modules/sns/aws"
#   version = "6.1.0"

#   name              = "transfer-service-analytical-platform"
#   display_name      = "transfer-service-analytical-platform"
#   signature_version = 2

#   kms_master_key_id = module.transfer_service_sns_kms.key_id

#   subscriptions = {
#     email = {
#       protocol = "email"
#       endpoint = "todo@fix.me" #TODO: un-hardcode
#     }
#   }
# }
