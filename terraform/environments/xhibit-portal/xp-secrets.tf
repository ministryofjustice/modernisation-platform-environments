# JSON Policy for accessing created secrets

resource "aws_secretsmanager_secret_policy" "test-policy" {
  secret_arn = aws_secretsmanager_secret.test.arn

  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [ {
    "Sid" : "AdministratorFullAccess",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "arn:aws:iam::"${data.aws_caller_identity.current.account_id}":role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_1c8be6e1a517e14c"
    },
    "Action" : "secretsmanager:*",
    "Resource" : "*"
  } ]
}
POLICY
}

# random placeholder secret to create the secret name

resource "random_password" "random_password" {

  length  = 32
  special = false
}

# placeholder plainttext data

data "aws_secretsmanager_secrets" "ssh" {
  filter {
    name = "plaintext"
    values = [<<EOT
----start----
gdfgdfgdfgdfg
----end----
EOT
    ]
  }
}

resource "aws_secretsmanager_secret" "test" {
  name        = "test"
  description = "testing plain text creation"
}

resource "aws_secretsmanager_secret_version" "test" {
  secret_id     = aws_secretsmanager_secret.test.id
  secret_string = data.aws_secretsmanager_secrets.ssh.plaintext
}

#resource "aws_secretsmanager_secret" "prtgadmin" {
#  name = "prtgadmin"
#  description = "Root admin account used for the PRTG system on the import machine"
#}
#
#resource "aws_secretsmanager_secret" "george" {
#  name = "george.pem"
#  description = "Private key for keypair george"
#}
#
#resource "aws_secretsmanager_secret" "aladmin" {
#  name = "aladmin"
#  description = "The local admin password for the user 'aladmin' on our domain joined EC2 instances"
#}
#
#resource "aws_secretsmanager_secret" "domainadmin-aladmin" {
#  name = "aladmin@cjse.sema.local"
#  description = "Domain admin account"
#}
#
#resource "aws_secretsmanager_secret" "zgit" {
#  name = "zgit.pem"
#  description = "key pair used for the zgit-server-xhibit-portal"
#}