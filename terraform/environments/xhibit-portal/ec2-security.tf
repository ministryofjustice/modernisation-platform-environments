#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instance
# This is required to enable SSH via Systems Manager
#------------------------------------------------------------------------------

resource "aws_iam_role" "xp_ec2_role" {
  name                 = "xp-ec2-role"
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
      Name = "xp-ec2-role"
    },
  )
}

resource "aws_iam_instance_profile" "ec2_xp_profile" {
  name = "xp-ec2-profile"
  role = aws_iam_role.xp_ec2_role.name
  path = "/"
}