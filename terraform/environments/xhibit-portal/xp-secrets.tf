# Get AWS SSO administrator & developer roles

data "aws_iam_roles" "admin" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "developer" {
  name_regex  = "AWSReservedSSO_modernisation-platform-developer.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

# Create blank secrets to update manually

resource "aws_secretsmanager_secret" "zgit" {
  name        = "${local.environment}/zgit.pem"
  description = "key pair used for the zgit-server-xhibit-portal"
  policy      = <<POLICY
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

  tags = local.tags
}

resource "aws_secretsmanager_secret" "prtgadmin" {
  name        = "${local.environment}/prtgadmin"
  description = "Root admin account used for the PRTG monitoring application on the import machine"
  policy      = <<POLICY
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

  tags = local.tags
}

resource "aws_secretsmanager_secret" "george" {
  name        = "${local.environment}/george.pem"
  description = "Private key for keypair george"
  policy      = <<POLICY
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

  tags = local.tags
}

resource "aws_secretsmanager_secret" "aladmin" {
  name        = "${local.environment}/aladmin"
  description = "The local admin password for the local user 'aladmin' on our domain joined EC2 instances"
  policy      = <<POLICY
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

  tags = local.tags
}

resource "aws_secretsmanager_secret" "domainadmin-aladmin" {
  name        = "${local.environment}/aladmin@cjse.sema.local"
  description = "Domain admin account"
  policy      = <<POLICY
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

  tags = local.tags
}