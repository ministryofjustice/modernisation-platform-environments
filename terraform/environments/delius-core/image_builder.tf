data "aws_iam_policy_document" "image_builder_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"]
    }
  }
}

resource "aws_iam_role" "EC2ImageBuilderDistributionCrossAccountRole" {
  name               = "EC2ImageBuilderDistributionCrossAccountRole"
  assume_role_policy = data.aws_iam_policy_document.image_builder_assume_role.json
}

resource "aws_iam_policy_attachment" "image_builder_template" {
  name       = "Ec2ImageBuilderCrossAccountDistributionAccess"
  roles      = [aws_iam_role.EC2ImageBuilderDistributionCrossAccountRole.name]
  policy_arn = "arn:aws:iam::aws:policy/Ec2ImageBuilderCrossAccountDistributionAccess"
}

data "aws_iam_policy_document" "image_builder_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      data.aws_kms_key.general_shared.arn,
      data.aws_kms_key.ebs_shared.arn,
    ]
  }
}

resource "aws_iam_policy" "image_builder_kms" {
  name   = "BusinessUnitKmsCmkPolicy"
  policy = data.aws_iam_policy_document.image_builder_kms.json
}

resource "aws_iam_policy_attachment" "image_builder_kms" {
  name       = "BusinessUnitKmsCmkPolicy"
  roles      = [aws_iam_role.EC2ImageBuilderDistributionCrossAccountRole.name]
  policy_arn = aws_iam_policy.image_builder_kms.arn
}

resource "aws_iam_policy" "ImageBuilderLaunchTemplatePolicy" {
  name   = "ImageBuilderLaunchTemplatePolicy"
  policy = data.aws_iam_policy_document.image_builder_kms.json
}

resource "aws_iam_policy_attachment" "ImageBuilderLaunchTemplatePolicy" {
  name       = "ImageBuilderLaunchTemplatePolicy"
  roles      = [aws_iam_role.EC2ImageBuilderDistributionCrossAccountRole.name]
  policy_arn = aws_iam_policy.ImageBuilderLaunchTemplatePolicy.arn
}