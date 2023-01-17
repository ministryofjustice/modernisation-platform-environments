resource "aws_iam_policy" "oracle_ec2_ssm_policy" {
  name        = "ssm_oracle_ec2_policy-${local.environment}"
  description = "allows SSM Connect logging"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:eu-west-2::log-group:/aws/ssm/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:*"
          ],
          "Resource" : [
            "arn:aws:ssm:eu-west-2:767123802783:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_logging_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.oracle_ec2_ssm_policy.arn
}