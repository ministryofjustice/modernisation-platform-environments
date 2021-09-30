#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instance
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
          "Action" : ["s3:ListBucket"],
          "Resource" : ["arn:aws:s3:::${module.s3-bucket.aws_s3_bucket.default.bucket}"]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : ["arn:aws:s3:::${module.s3-bucket.aws_s3_bucket.default}/*"]
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
  role = aws_iam_role.ssm_ec2_role.name
  path = "/"
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instance
# This is required to allow the ec2 instance to access the s3 bucket
#------------------------------------------------------------------------------

resource "aws_iam_role" "s3_ec2_role" {
  name                 = "s3-ec2-role"
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
      Name = "s3-ec2-role"
    },
  )
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "s3-ec2-profile"
  role = aws_iam_role.s3_ec2_role.name
  path = "/"
}
