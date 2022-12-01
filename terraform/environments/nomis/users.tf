# create a password for each user in data.github_team.dso_users.members
resource "random_password" "jumpserver" {
  for_each    = toset(data.github_team.dso_users.members)
  length      = 32
  min_special = 5
  special     = true
}

# create empty secret in secret manager
resource "aws_secretsmanager_secret" "jumpserver" {
  for_each = toset(data.github_team.dso_users.members)
  name     = "${local.secret_prefix}/${each.value}"
  policy   = data.aws_iam_policy_document.jumpserver_secrets[each.value].json
  #kms_key_id              = data.aws_kms_key.general_shared.id
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "jumpserver-user-${each.value}"
    },
  )
}

# populate secret with password
resource "aws_secretsmanager_secret_version" "jumpserver" {
  for_each      = random_password.jumpserver
  secret_id     = aws_secretsmanager_secret.jumpserver[each.key].id
  secret_string = each.value.result
}

# resource policy to restrict access to secret value to specific user and the CICD role used to deploy terraform
data "aws_iam_policy_document" "jumpserver_secrets" {
  for_each = toset(data.github_team.dso_users.members)
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.id}:secret:${local.secret_prefix}/*"]
  }
  statement {
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values = [
        "*:${each.value}@digital.justice.gov.uk",                       # specific user
        "${data.aws_iam_role.member_infrastructure_access.unique_id}:*" # terraform CICD role
      ]
    }
  }
}

