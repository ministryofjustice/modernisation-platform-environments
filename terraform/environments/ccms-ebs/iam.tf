## SSM Specific
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

resource "aws_iam_role_policy_attachment" "ssm_logging_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ec2_ssm_policy.arn
}

## Oracle EC2 Policies
resource "aws_iam_role" "role_stsassume_oracle_base" {
  name                 = "role_stsassume_oracle_base"
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
    { Name = lower(format("RoleSsm-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach Secrets Manager Policy to Role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "iam_instace_profile_ccms_base" {
  name = "iam_instace_profile_ccms_base"
  role = aws_iam_role.role_stsassume_oracle_base.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

# Cloudwatch Logging
resource "aws_iam_policy" "cw_logging_policy" {
  name        = "cw_log_policy-${local.environment}"
  description = "allows EC2 CW logging"

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
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "cw_logging_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.cw_logging_policy.arn
}

# RMAN policy
resource "aws_iam_policy" "rman_to_s3" {
  name        = "ec2_to_s3_policy-${local.environment}"
  description = "allows EC2 to write to S3"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets"
          ],
          "Resource": "arn:aws:s3:::*"
        },
        {
          "Effect": "Allow",
          "Action": ["s3:ListBucket"],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-*-dbbackup",
            "arn:aws:s3:::ccms-ebs-*-dbbackup/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-*-dbbackup",
            "arn:aws:s3:::ccms-ebs-*-dbbackup/*"
          ]
        }
      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "rman_to_s3_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.rman_to_s3.arn
}