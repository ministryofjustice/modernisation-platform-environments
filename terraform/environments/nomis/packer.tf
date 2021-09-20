#------------------------------------------------------------------------------
# Resources required for Packer
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Packer CICD User - user & group created manually as pipeline does not have
# required permissions
#------------------------------------------------------------------------------

# resource "aws_iam_user" "packer_member_user" {
#   name = "packer-member-user"
# }

data "aws_iam_user" "packer_member_user" {
  user_name = "packer-member-user"
}

# resource "aws_iam_access_key" "packer_member_user_key" {
#   user = aws_iam_user.packer_member_user.name
# }
# resource "aws_iam_group" "packer_member_group" {
#   name = "packer-member-group"
# }

data "aws_iam_group" "packer_member_group" {
  group_name = "packer-member-group"
}

# resource "aws_iam_group_membership" "packer_member" {
#   name = "packer-member-group-membership"

#   users = [
#     aws_iam_user.packer_member_user.name
#   ]

#   group = aws_iam_group.packer_member_group.name
# }

# build policy json for packer group member policy
data "aws_iam_policy_document" "packer_member_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.packer.arn]
  }
}

# attach inline policy
resource "aws_iam_group_policy" "packer_member_policy" {
  name   = "packer-member-policy"
  policy = data.aws_iam_policy_document.packer_member_policy.json
  # group      = aws_iam_group.packer_member_group.name
  group = "packer-member-group"
}

# Role to provide required packer permissions
data "aws_iam_policy_document" "packer_assume_role_policy" {
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
      identifiers = [data.aws_iam_user.packer_member_user.arn]
    }
  }
}

resource "aws_iam_role" "packer" {
  name               = "packer-build"
  assume_role_policy = data.aws_iam_policy_document.packer_assume_role_policy.json
  tags = merge(
    local.tags,
    {
      Name = "packer-build"
    },
  )
}

# build policy json for Packer base permissions
data "aws_iam_policy_document" "packer_minimum_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateKeypair",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
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
      "ec2:GetPasswordData",
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
      "ec2:ModifyImageAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/creator"
      values   = ["Packer"]
    }
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
}

# build policy json for Packer session manager permissions
data "aws_iam_policy_document" "packer_ssm_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:instance/*"]
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
    resources = ["arn:aws:ssm:*:*:session/&{aws:username}-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:GetInstanceProfile"]
    resources = [aws_iam_instance_profile.packer_ssm_profile.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.packer_ssm_role.arn]
  }
}

# combine policy json
data "aws_iam_policy_document" "packer_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.packer_minimum_permissions.json,
    data.aws_iam_policy_document.packer_ssm_permissions.json
  ]
}
# attach policy to role inline
resource "aws_iam_role_policy" "packer" {
  name   = "packer-minimum-permissions"
  role   = aws_iam_role.packer.id
  policy = data.aws_iam_policy_document.packer_combined.json
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by Packer build instance
# This is required to enable SSH via Systems Manager
#------------------------------------------------------------------------------

resource "aws_iam_role" "packer_ssm_role" {
  name                 = "packer-ssm-role"
  path                 = "/"
  max_session_duration = "3600"
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

resource "aws_iam_instance_profile" "packer_ssm_profile" {
  name = "packer-ssm-profile"
  role = aws_iam_role.packer_ssm_role.name
  path = "/"
}

#------------------------------------------------------------------------------
# Security Group to be used by Packer.  This is required as there is currently
# not a simple way to restrict Packer to only allow deleting of security groups
# it created (it does not tag the security group like other resources)
#------------------------------------------------------------------------------

resource "aws_security_group" "packer_security_group" {
  description = "Security Group for Packer builds"
  name        = "packer-build-${local.application_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.tags,
    {
      Name = "packer-build-sg"
    },
  )
}