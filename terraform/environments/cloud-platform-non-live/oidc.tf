# OIDC resources
# OIDC Provider is created as part of MP bootstrapping, we only need to create additional roles.

# OIDC Provider for GitHub Actions Admin
module "github_actions_administrator" {
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=b40748ec162b446f8f8d282f767a85b6501fd192" # v4.0.0
  github_repositories = ["ministryofjustice/cloud-platform-github-workflows"]
  role_name           = "github-actions-administrator"
  policy_arns         = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  policy_jsons        = [data.aws_iam_policy_document.oidc-deny-specific-actions.json]
  subject_claim       = "*"
  tags                = merge({ "Name" = "GitHub Actions Administrator" }, local.tags)
}

data "aws_iam_policy_document" "oidc-deny-specific-actions" {
  statement {
    effect = "Deny"
    actions = [
      "iam:ChangePassword",
      "iam:CreateLoginProfile",
      "iam:CreateUser",
      "iam:CreateGroup",
      "iam:DeleteUser",
      "iam:DeleteVirtualMFADevice"
    ]
    resources = ["*"]
  }
}

#TODO: Lock this down further or create a new role once we have more understanding of required permissions
