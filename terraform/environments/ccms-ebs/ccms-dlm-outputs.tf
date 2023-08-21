output "aws_iam_role_dlm_lifecycle_role_arn" {
description = "aws_iam_role dlm_lifecycle_role arn"
value = aws_iam_role.dlm_lifecycle_role.arn
}

output "aws_iam_role_dlm_lifecycle_role_name" {
description = "aws_iam_role dlm_lifecycle_role name"
value = aws_iam_role.dlm_lifecycle_role.name
}

#

output "aws_iam_role_policy_dlm_lifecycle_name" {
description = "aws_iam_role_policy dlm_lifecycle id"
value = aws_iam_role_policy.dlm_lifecycle.id
}

output "aws_iam_role_policy_dlm_lifecycle_name" {
description = "aws_iam_role_policy dlm_lifecycle name"
value = aws_iam_role_policy.dlm_lifecycle.name
}

output "aws_iam_role_policy_dlm_lifecycle_policy" {
description = "aws_iam_role_policy dlm_lifecycle policy"
value = aws_iam_role_policy.dlm_lifecycle.policy
}

output "aws_iam_role_policy_dlm_lifecycle_role" {
description = "aws_iam_role_policy dlm_lifecycle role"
value = aws_iam_role_policy.dlm_lifecycle.role
}

#

output "aws_dlm_lifecycle_policy_lifecyclerole_arn" {
description = "aws_dlm_lifecycle_policy lifecyclerole arn"
value = aws_dlm_lifecycle_policy.lifecyclerole.arn
}
