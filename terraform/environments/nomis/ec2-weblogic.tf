#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 weblogic instances
# This is based on the ec2-common-profile but additional permissions may be
# granted as needed
#------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_weblogic_role" {
  name                 = "ec2-weblogic-role"
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
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.ec2_common_policy.arn
  ]

  tags = merge(
    local.tags,
    {
      Name = "ec2-weblogic-role"
    },
  )
}

# create instance profile from IAM role
resource "aws_iam_instance_profile" "ec2_weblogic_profile" {
  name = "ec2-weblogic-profile"
  role = aws_iam_role.ec2_weblogic_role.name
  path = "/"
}
