#------------------------------------------------------------------------------
# Resources required for Packer
# Packer CICD user & group created manually as pipeline does not have
# required permissions.
# Packer user is only available in the Test account.  To avoid excessive use
# of count, roles and policies are created in all accounts but not attached
# to an IAM user (through use of count)
#------------------------------------------------------------------------------

# build policy json for packer group member policy
data "aws_iam_policy_document" "packer_member_policy" {
  count = local.environment == "test" ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.packer[0].arn]
  }
}

# attach inline policy
resource "aws_iam_group_policy" "packer_member_policy" {
  count  = local.environment == "test" ? 1 : 0
  name   = "packer-member-policy"
  policy = data.aws_iam_policy_document.packer_member_policy[0].json
  group  = "packer-member-group"
}

# Role to provide required packer permissions
data "aws_iam_policy_document" "packer_assume_role_policy" {
  count = local.environment == "test" ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["&{aws:username}"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:user/packer-member-user"]
    }
  }
}

resource "aws_iam_role" "packer" {
  count              = local.environment == "test" ? 1 : 0
  name               = "packer-build"
  assume_role_policy = data.aws_iam_policy_document.packer_assume_role_policy[0].json
  tags = merge(
    local.tags,
    {
      Name = "packer-build"
    },
  )
}

# build policy json for Packer base permissions
data "aws_iam_policy_document" "packer_minimum_permissions" {
  count = local.environment == "test" ? 1 : 0
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_107
    effect = "Allow"
    actions = [
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateKeypair",
      "ec2:CreateSnapshot",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",  # unfortunately Packer does not tag intermediate snapshots it creates
      "ec2:DeregisterImage", # unfortunately Packer does not tag intermediate images it creates
      "ec2:DescribeImageAttribute",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:ModifyImageAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:RegisterImage",
      "ec2:RunInstances"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:GetPasswordData",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/creator"
      values   = ["Packer", "packer", "ansible"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:AuthorizeSecurityGroupIngress"]
    resources = [aws_security_group.packer_security_group[0].arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteKeyPair"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:KeyPairName"
      values   = ["packer_*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["*"]
    condition { # only allow tagging of resources on creation
      test     = "StringLike"
      variable = "ec2:CreateAction"
      values = [
        "RunInstances",
        "CopyImage",
        "CreateImage",
        "CreateKeypair",
        "CreateSnapshot",
        "CreateVolume",
        "RegisterImage"
      ]
    }
  }

  statement { # need this as Packer seems to copy the image and then tag it
    effect  = "Allow"
    actions = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:eu-west-2::image/ami-*",
      "arn:aws:ec2:eu-west-2::snapshot/snap-*",
      "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.id}:key-pair/packer*"
    ]
  }

  statement { # need so Packer can use CMK to encrypt snapshots so can be shared with other accounts
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [aws_kms_key.nomis-cmk[0].arn]
  }
}

# build policy json for Packer session manager permissions
data "aws_iam_policy_document" "packer_ssm_permissions" {
  count = local.environment == "test" ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.id}:instance/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/creator"
      values   = ["Packer"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ssm:eu-west-2::document/AWS-StartPortForwardingSession"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
    resources = ["arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.id}:session/packer-member-user-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:GetInstanceProfile"]
    resources = [aws_iam_instance_profile.packer_ssm_profile[0].arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.packer_ssm_role[0].arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["*"]
  }
}

# some extra permissions required for Ansible ec2 module
# it might be an idea to create another role for Ansible instead
data "aws_iam_policy_document" "packer_ansible_permissions" {
  count = local.environment == "test" ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeVpcs",
      "ec2:DescribeKeyPairs",
      "sts:DecodeAuthorizationMessage",
      "kms:ReEncrypt*", # for building from cmk-encrypted AMIs
      "logs:DeleteLogGroup",
      "secretsmanager:DeleteResourcePolicy"
    ]
    resources = ["*"]
  }
}

# combine policy json
data "aws_iam_policy_document" "packer_combined" {
  count = local.environment == "test" ? 1 : 0
  source_policy_documents = [
    data.aws_iam_policy_document.packer_minimum_permissions[0].json,
    data.aws_iam_policy_document.packer_ssm_permissions[0].json,
    data.aws_iam_policy_document.packer_ansible_permissions[0].json
  ]
}
# attach policy to role inline
resource "aws_iam_role_policy" "packer" {
  count  = local.environment == "test" ? 1 : 0
  name   = "packer-minimum-permissions"
  role   = aws_iam_role.packer[0].id
  policy = data.aws_iam_policy_document.packer_combined[0].json
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by Packer build instance
# This is required to enable SSH via Systems Manager
# and for access to S3 bucket
#------------------------------------------------------------------------------

resource "aws_iam_role" "packer_ssm_role" {
  count                = local.environment == "test" ? 1 : 0
  name                 = "packer-ssm-role"
  path                 = "/"
  max_session_duration = "7200" # builds can take up to 1hr 45mins
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  tags = merge(
    local.tags,
    {
      Name = "packer-ssm-role"
    },
  )
}

# build policy document for access to s3 bucket
data "aws_iam_policy_document" "packer_s3_bucket_access" {
  count = local.environment == "test" ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.s3-bucket.bucket.arn,
      module.nomis-db-backup-bucket.bucket.arn,
      "${module.s3-bucket.bucket.arn}/*",
      "${module.nomis-db-backup-bucket.bucket.arn}/*"
    ]
  }
}

# attach s3 document as inline policy
resource "aws_iam_role_policy" "packer_s3_bucket_access" {
  count  = local.environment == "test" ? 1 : 0
  name   = "nomis-apps-bucket-access"
  role   = aws_iam_role.packer_ssm_role[0].name
  policy = data.aws_iam_policy_document.packer_s3_bucket_access[0].json
}

# create instance profile from role
resource "aws_iam_instance_profile" "packer_ssm_profile" {
  count = local.environment == "test" ? 1 : 0
  name  = "packer-ssm-profile"
  role  = aws_iam_role.packer_ssm_role[0].name
  path  = "/"
}

#------------------------------------------------------------------------------
# Security Group to be used by Packer.  This is required as there is currently
# not a simple way to restrict Packer to only allow deleting of security groups
# it created (it does not tag the security group like other resources)
#------------------------------------------------------------------------------

resource "aws_security_group" "packer_security_group" {
  count = local.environment == "test" ? 1 : 0
  #checkov:skip=CKV2_AWS_5
  description = "Security Group for Packer builds"
  name        = "packer-build-${local.application_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }
  tags = merge(
    local.tags,
    {
      Name = "packer-build-sg"
    },
  )
}
