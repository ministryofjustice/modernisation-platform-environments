# Allow the modernisation-platform-oidc-cicd role to assume the
# AWS supplied role AWSBackupDefaultServiceRole which allows us
# to write snapshots to the Backup Vault.   We use Backup Vault
# to manage EC2 snapshots for Oracle hosts as these are only
# created sporadically, e.g. ahead of a service release, and will
# therefore not be continually overwritten.  Writing them to a
# backup vault allows them to timeout without being overwritten.

data "aws_iam_role" "AWSBackupDefaultServiceRole" {
  name = "AWSBackupDefaultServiceRole"
}

# Decode the existing assume role policy
locals {
  existing_statements = try(
    jsondecode(data.aws_iam_role.AWSBackupDefaultServiceRole.assume_role_policy)["Statement"],
    []
  )
  new_statement = {
    Effect = "Allow",
    Principal = {
      AWS = "arn:aws:iam::${var.account_info.id}:role/modernisation-platform-oidc-cicd"
    },
    Action = "sts:AssumeRole"
  }
  combined_statements = concat(local.existing_statements, [local.new_statement])
}

# Create the combined policy
data "aws_iam_policy_document" "merged_trust_policy" {
  dynamic "statement" {
    for_each = toset(local.combined_statements)

       content {
            effect    = statement.value["Effect"]
            actions   = [statement.value["Action"]]
            principals {
                type        = keys(statement.value["Principal"])[0]
                identifiers = toset([statement.value["Principal"][keys(statement.value["Principal"])[0]]])
            }
       }
  }
}
resource "aws_iam_policy" "new_trust_policy" {
  name        = "AWSBackupDefaultServiceRolePolicy"
  description = "Updated trust policy for AWSBackupDefaultServiceRole"

  policy = data.aws_iam_policy_document.merged_trust_policy.json
}

resource "aws_iam_policy_attachment" "attach_policy_to_AWSBackupDefaultServiceRole" {
  name       = "attach-policy-to-AWSBackupDefaultServiceRole"
  roles      = ["AWSBackupDefaultServiceRole"]
  policy_arn = aws_iam_policy.new_trust_policy.arn
}


