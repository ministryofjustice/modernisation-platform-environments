output "aws_iam_role_dlm_lifecycle_role_arn" {
  description = "aws_iam_role dlm_lifecycle_role arn"
  value       = try(aws_iam_role.dlm_lifecycle_role[*].arn, "None")
}

output "aws_iam_role_dlm_lifecycle_role_name" {
  description = "aws_iam_role dlm_lifecycle_role name"
  value       = try(aws_iam_role.dlm_lifecycle_role[*].name, "None")
}

#

output "aws_iam_role_policy_dlm_lifecycle_id" {
  description = "aws_iam_role_policy dlm_lifecycle id"
  value       = try(aws_iam_role_policy.dlm_lifecycle[*].id, "None")
}

output "aws_iam_role_policy_dlm_lifecycle_name" {
  description = "aws_iam_role_policy dlm_lifecycle name"
  value       = try(aws_iam_role_policy.dlm_lifecycle[*].name, "None")
}

output "aws_iam_role_policy_dlm_lifecycle_policy" {
  description = "aws_iam_role_policy dlm_lifecycle policy"
  value       = try(aws_iam_role_policy.dlm_lifecycle[*].policy, "None")
}

output "aws_iam_role_policy_dlm_lifecycle_role" {
  description = "aws_iam_role_policy dlm_lifecycle role"
  value       = try(aws_iam_role_policy.dlm_lifecycle[*].role, "None")
}

#

output "aws_dlm_lifecycle_policy_lifecyclerole_arn" {
  description = "aws_dlm_lifecycle_policy lifecyclerole arn"
  value       = try(aws_dlm_lifecycle_policy.lifecyclerole[*].arn, "None")
}
