#------------------------------------------------------------------------------
# Resources required for Packer
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Packer CICD User
#------------------------------------------------------------------------------
resource "aws_iam_user" "packer_member_user" {
  name = "packer-member-user"
}

resource "aws_iam_access_key" "packer_member_user_key" {
  user = aws_iam_user.packer_member_user.name
}
resource "aws_iam_group" "packer_member_group" {
  name = "packer-member-group"
}

resource "aws_iam_policy" "policy" {
  name        = "packer-member-policy"
  description = "IAM Policy for packer member user"
  policy = jsonencode({ #tfsec:ignore:AWS099
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.packer.arn
      },
    ]
  })
}

resource "aws_iam_group_policy_attachment" "aws_config_attach" {
  group      = aws_iam_group.packer_member_group.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_group_membership" "packer_member" {
  name = "packer-member-group-membership"

  users = [
    aws_iam_user.packer_member_user.name
  ]

  group = aws_iam_group.packer_member_group.name
}

# Role to provide required packer permissions
resource "aws_iam_role" "packer" {
  name = "packer-build"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : aws_iam_user.packer_member_user.arn
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
  })

  tags = merge(
    local.tags,
    {
      Name = "packer-build"
    },
  )
}

# policy for the packer role, and attach to role
resource "aws_iam_role_policy" "packer" {
  name = "packer-minimum-permissions"
  role = aws_iam_role.packer.id

  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
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
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AttachVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/creator" : "Packer"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "ssm:StartSession",
        "Resource" : "arn:aws:ec2:eu-west-2:612659970365:instance/*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/creator" : "Packer"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "ssm:StartSession",
        "Resource" : "arn:aws:ssm:eu-west-2::document/AWS-StartPortForwardingSession"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ],
        "Resource" : [
          "arn:aws:ssm:*:*:session/$${aws:username}-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteKeyPair"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:KeyPairName" : "packer_*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:GetInstanceProfile",
        "Resource" : "${aws_iam_instance_profile.packer_ssm_profile.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "${aws_iam_instance_profile.packer_ssm_role.arn}"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by Packer build instance
# This is required to enable SSH via Systems Manager
#------------------------------------------------------------------------------

resource "aws_iam_role" "packer_ssm_role" {
  name                 = "packer_ssm_role"
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
      Name = "packer_ssm_role"
    },
  )
}

resource "aws_iam_instance_profile" "packer_ssm_profile" {
  name = "packer_ssm_profile"
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
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}