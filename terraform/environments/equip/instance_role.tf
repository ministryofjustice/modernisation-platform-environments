resource "aws_iam_role" "ssm-instance-role-moj" {
  name = "ssm-instance-role-moj"
  path = "/"

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

resource "aws_iam_instance_profile" "instance-profile-moj" {
  name = "instance-profile-moj"
  role = aws_iam_role.ssm-instance-role-moj.name
}

resource "aws_iam_policy_attachment" "this" {
  name       = "policy_attachment"
  roles      = [aws_iam_role.ssm-instance-role-moj.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "this_tags" {
  name       = "policy_attachment_tags"
  roles      = [aws_iam_role.ssm-instance-role-moj.name]
  policy_arn = aws_iam_policy.policy-ssm.arn
}

resource "aws_iam_policy_attachment" "citrix_adc_instance_attachment" {
  name       = "citrix_adc_instance_attachment"
  roles      = [aws_iam_role.ssm-instance-role-moj.name]
  policy_arn = aws_iam_policy.citrix_adc_instance_policy.arn
}

resource "aws_iam_policy_attachment" "read_list_s3_access_attachment" {
  count      = local.is-development ? 1 : 0
  name       = "read_list_s3_access_attachment"
  roles      = [aws_iam_role.ssm-instance-role-moj.name]
  policy_arn = aws_iam_policy.read_list_s3_access_policy[0].arn
}
