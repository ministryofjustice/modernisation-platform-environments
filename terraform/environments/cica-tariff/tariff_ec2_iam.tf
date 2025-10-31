
resource "aws_iam_instance_profile" "tariff_instance_profile" {
  name = "${local.application_name}-instance-profile"
  role = aws_iam_role.tariff_instance_role.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-instance-profile"
    }
  )
}

resource "aws_iam_role" "tariff_instance_role" {
  name = "${local.application_name}-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-instance-role"
    }
  )
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}



resource "aws_iam_role_policy_attachment" "tariff_instance_ssm" {
  role       = aws_iam_role.tariff_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "tariff_instance_cica_s3_access_data" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject*"]
    resources = [
      for bucket in local.cica_s3_resource : "${bucket}/export/*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:ListBucket*"]
    resources = [
      for bucket in local.cica_s3_resource : "${bucket}"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["export/*"]
    }
  }
}

resource "aws_iam_policy" "tariff_instance_cica_s3_access_policy" {
  name        = "${local.application_name}-instance-cicas3-policy"
  description = "Policy to allow access to CICA Storage Gateway S3"
  policy      = data.aws_iam_policy_document.tariff_instance_cica_s3_access_data.json
}

resource "aws_iam_role_policy_attachment" "tariff_instance_cica_s3_access_attach" {
  role       = aws_iam_role.tariff_instance_role.name
  policy_arn = aws_iam_policy.tariff_instance_cica_s3_access_policy.arn
}
