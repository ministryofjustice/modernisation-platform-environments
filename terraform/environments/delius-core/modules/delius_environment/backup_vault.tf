# Allow the modernisation-platform-oidc-cicd role to assume the
# AWS supplied role AWSBackupDefaultServiceRole which allows us
# to write snapshots to the Backup Vault.   We use Backup Vault
# to manage EC2 snapshots for Oracle hosts as these are only
# created sporadically, e.g. ahead of a service release, and will
# therefore not be continually overwritten.  Writing them to a
# backup vault allows them to timeout without being overwritten.
data "aws_iam_policy_document" "assume_AWSBackupDefaultServiceRole" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_info.id}:role/modernisation-platform-oidc-cicd"]
    }
  }
}

resource "aws_iam_role_policy" "assume_AWSBackupDefaultServiceRole" {
  role   = "AWSBackupDefaultServiceRole"
  policy = data.aws_iam_policy_document.assume_AWSBackupDefaultServiceRole.json
}