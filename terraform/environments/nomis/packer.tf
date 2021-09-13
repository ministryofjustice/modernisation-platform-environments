#------------------------------------------------------------------------------
# Resources required for Packer
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Packer CICD User
#------------------------------------------------------------------------------
resource "aws_iam_user" "packer_member_user" {
  name = "packer-member-user"
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

resource "aws_iam_group_membership" "packer-member" {
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
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CopyImage",
          "ec2:CreateImage",
          "ec2:CreateKeypair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
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
          "ec2:RunInstances",
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AttachVolume",
          "ec2:DeleteKeyPair",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DeregisterImage",
          "ec2:DetachVolume",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/creator" : "Packer"
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by Packer build instance
# This is required enable SSH via Systems Manager
#------------------------------------------------------------------------------

resource "aws_iam_role" "packer_ssm_role" {
  name = "packer_ssm_role"
  path = "/"
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