# ##########################################################################################
# # ------------------------Comment out file if not required----------------------------------
# ##########################################################################################

# If you are getting errors with this code it might because there are protections that have not been disabled. login to the example account
# and go to the protected resources on the aws shield and remove any that have errors. once you have finished with what you are doing and are 
# hashing out both the import and the resource you will need to remove the shield from the state file before running an apply.


# import {
#   id = "c6f3ba81-c457-40f6-bd1f-30e777f60c27/FMManagedWebACLV2-shield_advanced_auto_remediate-1652297838425/REGIONAL"
#   to = module.shield.aws_wafv2_web_acl.main
# }

# module "shield" {
#   source = "../../modules/shield_advanced"
#   providers = {
#     aws.modernisation-platform = aws.modernisation-platform
#   }
#   application_name     = local.application_name
#   excluded_protections = local.application_data.accounts[local.environment].excluded_protections
#   resources = {
#     certificate_lb = {
#       arn = aws_lb.certificate_example_lb.arn
#     }
#     public_lb = {
#       action = "count",
#       arn    = aws_lb.external.arn
#     }
#   }
#   waf_acl_rules = {
#     example = {
#       "action"    = "count",
#       "name"      = "example-count-rule",
#       "priority"  = 0,
#       "threshold" = "1000"
#     }
#   }
# }
