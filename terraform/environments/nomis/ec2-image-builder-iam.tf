# Required permissions for Image Builder AMI distribution
# https://docs.aws.amazon.com/imagebuilder/latest/userguide/cross-account-dist.html
# These permissions are needed in all ami destination accounts

data "aws_iam_policy_document" "image-builder-distro-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"]
    }
  }
}

resource "aws_iam_role" "image-builder-distro-role" {
  name               = "EC2ImageBuilderDistributionCrossAccountRole"
  assume_role_policy = data.aws_iam_policy_document.image-builder-distro-assume-role.json
  tags = merge(
    local.tags,
    {
      Name = "image-builder-distro-role"
    },
  )

}


resource "aws_iam_role_policy_attachment" "image-builder-distro-policy-attach" {
  policy_arn = "arn:aws:iam::aws:policy/Ec2ImageBuilderCrossAccountDistributionAccess"
  role       = aws_iam_role.image-builder-distro-role
}


data "aws_iam_policy_document" "image-builder-launch-template-policy" {
  statement {
    effect = "Allow"
    actions = ["ec2:CreateLaunchTemplateVersion",
      "ec2:ModifyLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "image-builder-distro-kms-policy" {
  statement {
    effect = "Allow"
    actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:ReEncryptFrom",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrant",
        "kms:RevokeGrant"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ]
    }
  }
}

data "aws_iam_policy_document" "image-builder-combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.image-builder-distro-kms-policy.json,
    data.aws_iam_policy_document.image-builder-launch-template-policy.json
  ]
}

resource "aws_iam_policy" "image-builder-combined-policy" {
  name        = "image-builder-distro-additional-policy"
  path        = "/"
  description = "Image Builder Required Launch Template and KMS Permissions"
  policy      = data.aws_iam_policy_document.image-builder-combined.json
  tags = merge(
    local.tags,
    {
      Name = "image-builder-distro-additional-policy"
    },
  )
}

resource "aws_iam_role_policy_attachment" "image-builder-launch-tempplate-attach" {
  policy_arn = aws_iam_policy.image-builder-combined-policy.arn
  role       = aws_iam_role.image-builder-distro-role

}
