# Allow the modernisation-platform-oidc-cicd role to assume the
# new role oracle_ec2_backup_service_role which allows us
# to write snapshots to the Backup Vault.   We use Backup Vault
# to manage EC2 snapshots for Oracle hosts as these are only
# created sporadically, e.g. ahead of a service release, and will
# therefore not be continually overwritten.  Writing them to a
# backup vault allows them to timeout without being overwritten.
# The AWSBackupServiceRolePolicyForBackup is managed by AWS and
# is documented at: https://docs.aws.amazon.com/aws-backup/latest/devguide/iam-service-roles.html

# New IAM role to allow writing of AWS EC2 snapshots of Oracle Hosts to Backup Vault
resource "aws_iam_role" "oracle_ec2_backup_service_role" {
  name = "oracle_ec2_backup_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ForAnyValue:ArnLike": {
          "aws:PrincipalArn": "arn:aws:iam::${var.account_info.id}:role/modernisation-platform-oidc-cicd"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "oracle_ec2_backup_service_policy_attachment" {
  role       = aws_iam_role.oracle_ec2_backup_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}