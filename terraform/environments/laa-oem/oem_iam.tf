resource "aws_iam_policy" "ec2_ssm_policy" {
  name        = "ssm_ec2_policy-${local.environment}"
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
        },
        {
          "Action" : "s3:GetObject",
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:s3:::patch-baseline-snapshot-eu-west-2/*",
            "arn:aws:s3:::eu-west-2-birdwatcher-prod/*",
            "arn:aws:s3:::aws-windows-downloads-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-document-attachments-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-distributor-file-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-packages-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-eu-west-2/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role" "role_stsassume_oem_base" {
  name                 = "role_stsassume_oem_base"
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
  tags = merge(local.tags,
    { Name = lower(format("RoleSsm-%s-%s-OEM-Base", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_logging_oem_base" {
  role       = aws_iam_role.role_stsassume_oem_base.name
  policy_arn = aws_iam_policy.ec2_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_policy_oem_base" {
  role       = aws_iam_role.role_stsassume_oem_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_oem_base" {
  role       = aws_iam_role.role_stsassume_oem_base.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ec2_readonly_policy_oem_base" {
  role       = aws_iam_role.role_stsassume_oem_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "iam_instace_profile_oem_base" {
  name = "iam_instace_profile_oem_base"
  role = aws_iam_role.role_stsassume_oem_base.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-%s-OEM-Base", local.application_name, local.environment)) }
  )
}
