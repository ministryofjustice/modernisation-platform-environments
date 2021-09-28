#------------------------------------------------------------------------------
# Instance profile to be assumed by Packer build instance
# This is required to enable SSH via Systems Manager
#------------------------------------------------------------------------------

resource "aws_iam_role" "ssm_ec2_role" {
  name                 = "ssm-ec2-role"
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
      Name = "ssm-ec2-role"
    },
  )
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ssm-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
  path = "/"
}
