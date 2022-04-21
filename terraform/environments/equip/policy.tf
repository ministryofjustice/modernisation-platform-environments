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
