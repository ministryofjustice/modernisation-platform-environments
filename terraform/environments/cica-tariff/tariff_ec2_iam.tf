
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