# IAM Role for shared ClamAV Server

resource "aws_iam_role" "clamav" {
  name                 = "${local.application_name}-clamav-ec2-role"
  path                 = "/"
  max_session_duration = 3600
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = "${local.application_name}-clamav-ec2-role" }
  )
}

resource "aws_iam_role_policy_attachment" "clamav_ssm" {
  role       = aws_iam_role.clamav.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "clamav" {
  name = "${local.application_name}-clamav-ec2-instance-profile"
  role = aws_iam_role.clamav.name
  path = "/"
  tags = merge(local.tags,
    { Name = "${local.application_name}-clamav-ec2-instance-profile" }
  )
}
