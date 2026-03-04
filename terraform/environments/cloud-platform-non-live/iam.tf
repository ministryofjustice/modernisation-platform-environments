#### IAM resources for this member account ####
resource "aws_iam_user" "admin" {
  count = local.application_data.accounts[local.environment].admin_iam_user_name == null ? 0 : 1

  name          = local.application_data.accounts[local.environment].admin_iam_user_name
  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "admin" {
  count = local.application_data.accounts[local.environment].admin_iam_user_name == null ? 0 : 1

  user       = aws_iam_user.admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "admin" {
  count = local.application_data.accounts[local.environment].admin_iam_user_name == null ? 0 : 1

  user = aws_iam_user.admin[0].name
}

output "admin_iam_user_name" {
  description = "IAM admin username (if created)."
  value       = local.application_data.accounts[local.environment].admin_iam_user_name
}

output "admin_iam_access_key_id" {
  description = "Access key id for the created IAM admin user (if created)."
  value       = try(aws_iam_access_key.admin[0].id, null)
  sensitive   = true
}

output "admin_iam_secret_access_key" {
  description = "Secret access key for the created IAM admin user (if created)."
  value       = try(aws_iam_access_key.admin[0].secret, null)
  sensitive   = true
}
