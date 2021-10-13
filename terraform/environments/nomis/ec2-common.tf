#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instance
# This is required to enable SSH via Systems Manager
# and also to allow access to an S3 bucket in which 
# Oracle and Weblogic installation files are held
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

# create policy document for access to s3 bucket
data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::s3-bucket20210929163229537900000001",
    "arn:aws:s3:::s3-bucket20210929163229537900000001/*"] # todo: reference bucket module output
  }
}

# attach s3 document as inline policy
resource "aws_iam_role_policy" "s3_bucket_access" {
  name   = "nomis-apps-bucket-access"
  role   = aws_iam_role.ssm_ec2_role.name
  policy = data.aws_iam_policy_document.s3_bucket_access.json
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2_role.name
  path = "/"
}