# JSON Policy for accessing created secrets

resource "aws_secretsmanager_secret_policy" "test-policy" {
  secret_arn = aws_secretsmanager_secret.test-secret.arn

  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [ {
    "Sid" : "AdministratorFullAccess",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "arn:aws:iam::276038508461:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_1c8be6e1a517e14c"
    },
    "Action" : "secretsmanager:*",
    "Resource" : "*"
  } ]
}
POLICY
}

# random placeholder secret

resource "random_password" "random_password" {

  length  = 32
  special = false
}

# Secret names to create and updated manually in console

resource "aws_secretsmanager_secret" "test-secret" {
  name = "test-secret"
}

resource "aws_secretsmanager_secret_version" "test-secret" {
  secret_id     = aws_secretsmanager_secret.test-secret.id
  secret_string = random_password.random_password.result
}

#resource "aws_secretsmanager_secret" "prtgadmin" {
#  name = "prtgadmin"
#}
#
#resource "aws_secretsmanager_secret" "george" {
#  name = "george.pem"
#}
#
#resource "aws_secretsmanager_secret" "aladmin" {
#  name = "aladmin"
#}
#
#resource "aws_secretsmanager_secret" "example" {
#  name = "example"
#}