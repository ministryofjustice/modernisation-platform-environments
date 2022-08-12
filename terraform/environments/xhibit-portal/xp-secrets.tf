# Get AWS SSO administrator & developer roles

data "aws_iam_roles" "admin" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "developer" {
  name_regex  = "AWSReservedSSO_modernisation-platform-developer.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

# JSON Policy for accessing created secrets

#resource "aws_secretsmanager_secret_policy" "test-policy" {
#  secret_arn = aws_secretsmanager_secret.test.arn
#
#  policy = <<POLICY
#{
#  "Version" : "2012-10-17",
#  "Statement" : [ {
#    "Sid" : "AdministratorFullAccess",
#    "Effect" : "Allow",
#    "Principal" : {
#      "AWS" : "arn:aws:iam::"${data.aws_caller_identity.current.account_id}":role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_1c8be6e1a517e14c"
#    },
#    "Action" : "secretsmanager:*",
#    "Resource" : "*"
#  } ]
#}
#POLICY
#}

# random string generator used as a placeholder

resource "random_password" "random_password" {
  length  = 32
  special = false
}

# placeholder plainttext data

resource "aws_secretsmanager_secret" "test" {
  name                    = "test"
  description             = "testing plain text creation"
  recovery_window_in_days = 0
  policy                  = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [ {
    "Sid" : "AdministratorFullAccess",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "${sort(data.aws_iam_roles.admin.arns)[0]}"
    },
    "Action" : "secretsmanager:*",
    "Resource" : "*"
  },
  {
    "Sid" : "MPDeveloperFullAccess",
    "Effect" : "Allow",
    "Principal" : {
       "AWS" : "${sort(data.aws_iam_roles.developer.arns)[0]}"
    },
    "Action" : "secretsmanager:*",  
    "Resource" : "*"
  } ]
}
POLICY
}


resource "aws_secretsmanager_secret_version" "test" {
  secret_id     = aws_secretsmanager_secret.test.id
  secret_string = random_password.random_password.result
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