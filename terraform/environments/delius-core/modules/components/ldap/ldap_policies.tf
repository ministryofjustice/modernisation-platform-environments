# module "ldap_ecs_policies" {
#   source       = "../../helpers/ecs_policies"
#   env_name     = var.env_name
#   service_name = "ldap"
#   tags         = var.tags
#   extra_exec_role_allow_statements = [
#     "elasticfilesystem:ClientRootAccess",
#     "elasticfilesystem:ClientWrite",
#     "elasticfilesystem:ClientMount"
#   ]
#   extra_task_role_policies = {
#     migration_s3 = data.aws_iam_policy_document.migration_s3
#   }
# }

# data "aws_iam_policy_document" "migration_s3" {
#   statement {
#     sid    = "CustomPolicyActions"
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:ListBucket",
#       "s3:HeadBucket",
#       "s3:HeadObject"
#     ]
#     resources = [
#       module.s3_bucket_migration.bucket.arn
#     ]
#   }
# }
