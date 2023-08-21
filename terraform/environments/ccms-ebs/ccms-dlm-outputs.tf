output "aws_iam_role_dlm_lifecycle_role_arn" {
  description = "aws_iam_role dlm_lifecycle_role arn"
  value       = aws_iam_role.dlm_lifecycle_role[count.index].arn
}

output "aws_iam_role_dlm_lifecycle_role_name" {
  description = "aws_iam_role dlm_lifecycle_role name"
  value       = aws_iam_role.dlm_lifecycle_role[count.index].name
}

#

output "aws_iam_role_policy_dlm_lifecycle_id" {
  description = "aws_iam_role_policy dlm_lifecycle id"
  value       = aws_iam_role_policy.dlm_lifecycle[count.index].id
}

output "aws_iam_role_policy_dlm_lifecycle_name" {
  description = "aws_iam_role_policy dlm_lifecycle name"
  value       = aws_iam_role_policy.dlm_lifecycle[count.index].name
}

output "aws_iam_role_policy_dlm_lifecycle_policy" {
  description = "aws_iam_role_policy dlm_lifecycle policy"
  value       = aws_iam_role_policy.dlm_lifecycle[count.index].policy
}

output "aws_iam_role_policy_dlm_lifecycle_role" {
  description = "aws_iam_role_policy dlm_lifecycle role"
  value       = aws_iam_role_policy.dlm_lifecycle[count.index].role
}

#

output "aws_dlm_lifecycle_policy_lifecyclerole_arn" {
  description = "aws_dlm_lifecycle_policy lifecyclerole arn"
  value       = aws_dlm_lifecycle_policy.lifecyclerole[count.index].arn
}
