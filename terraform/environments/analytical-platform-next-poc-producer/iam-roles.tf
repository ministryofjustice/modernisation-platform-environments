# RETIRED
# module "glue_crawler_iam_role" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "5.59.0"

#   create_role = true

#   role_name         = "glue-crawler"
#   role_requires_mfa = false

#   trusted_role_services = ["glue.amazonaws.com"]

#   custom_role_policy_arns = [
#     "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
#     module.glue_crawler_iam_policy.arn
#   ]
# }
