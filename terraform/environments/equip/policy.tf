resource "aws_iam_policy" "policy-ssm" {
  name        = "policy-ssm-moj"
  path        = "/"
  description = "SSM Policy for Baseline Patch"

  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceStatus"
        ],
        "Resource" : "*"
      }
    ]
  })
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "citrix_adc_instance_policy" {
  name        = "citrix_adc_instance_policy"
  path        = "/"
  description = "Policy for Citrix NetScaler instance"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "autoscaling:*",
          "sns:*",
          "sqs:*",
          "iam:SimulatePrincipalPolicy",
          "iam:GetRole"
        ],
        "Resource" : "*"
      }
    ]
  })
}
