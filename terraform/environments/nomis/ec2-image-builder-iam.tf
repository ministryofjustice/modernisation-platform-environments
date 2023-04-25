# Required permissions for Image Builder AMI distribution
# https://docs.aws.amazon.com/imagebuilder/latest/userguide/cross-account-dist.html
# These permissions are needed in all ami destination accounts
data "aws_caller_identity" "mod-platform" {
  provider = aws.modernisation-platform
}

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

#tfsec:ignore:aws-iam-no-policy-wildcards AWS Managed Policy
resource "aws_iam_role_policy_attachment" "image-builder-distro-policy-attach" {
  policy_arn = "arn:aws:iam::aws:policy/Ec2ImageBuilderCrossAccountDistributionAccess"
  role       = aws_iam_role.image-builder-distro-role.name
}

#tfsec:ignore:aws-iam-no-policy-wildcards needed to look up launch template ids from another account
data "aws_iam_policy_document" "image-builder-launch-template-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeLaunchTemplates"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplateVersion",
      "ec2:ModifyLaunchTemplate",
      "ec2:CreateTags"
    ]
    # coalescelist as there are no weblogics in prod at the moment and empty resource is not acceptable
    # resources = coalescelist([for item in module.weblogic : item.launch_template_arn], ["arn:aws:ec2:${local.region}:${data.aws_caller_identity.current.id}:launch-template/dummy"])
    resources = ["arn:aws:ec2:${local.region}:${data.aws_caller_identity.current.id}:launch-template/*"]
  }
}

data "aws_iam_policy_document" "image-builder-distro-kms-policy" {
  statement {
    effect = "Allow"
    #tfsec:ignore:aws-iam-no-policy-wildcards
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    # Allow access to the AMI encryption key
    resources = [module.environment.kms_keys["ebs"].arn]
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
  role       = aws_iam_role.image-builder-distro-role.name

}

# role for a provider to lookup launch templates from the core-shared-services account to avoid hard-coding

data "aws_iam_policy_document" "mod-platform-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.mod-platform.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "core-services-launch-template-reader" {
  name               = "NomisLaunchTemplateReaderRole"
  assume_role_policy = data.aws_iam_policy_document.mod-platform-assume-role.json
  tags = merge(
    local.tags,
    {
      Name = "core-services-launch-template-reader"
    },
  )

}

data "aws_iam_policy_document" "launch-template-reader-policy-doc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "launch-template-reader-policy" {
  name        = "launch-template-reader-policy"
  path        = "/"
  description = "Policy to Allow Core Shared Services Account to Look up Launch Templates"
  policy      = data.aws_iam_policy_document.launch-template-reader-policy-doc.json
  tags = merge(
    local.tags,
    {
      Name = "launch-template-reader-policy"
    },
  )
}

resource "aws_iam_role_policy_attachment" "launch-template-reader-policy-attach" {
  policy_arn = aws_iam_policy.launch-template-reader-policy.arn
  role       = aws_iam_role.core-services-launch-template-reader.name

}

