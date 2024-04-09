# Database Migration Service requires the below IAM Roles to be created before replication instances can be created. 

# Define IAM role for DMS S3 Endpoint
resource "aws_iam_role" "dms-endpoint-role" {
  name               = "dms-endpoint-access-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

# Define S3 IAM policy for DMS S3 Endpoint
resource "aws_iam_policy" "dms-s3-ep-role-policy" {
  name = "dms-s3-target-ep-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "kms:*"
            ],
            "Resource": [
            "arn:aws:s3::*:dms-*/*",
            "arn:aws:s3::*:dms-*"
            ]
        }
    ]
}
EOF
}

# Attach predefined IAM Policy to the Role for DMS S3 Endpoint
resource "aws_iam_role_policy_attachment" "dms-endpoint-role" {
  role       = aws_iam_role.dms-endpoint-role.name
  policy_arn = aws_iam_policy.dms-s3-ep-role-policy.arn
}

# ==========================================================================

# Create DMS VPC EC2 Role
resource "aws_iam_role" "dms-vpc-role" {
  name               = "dms-vpc-mng-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

# Attach IAM Policy to the predefined DMS VPC EC2 Role
resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# ==========================================================================

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  name               = "dms-cloudwatch-logs-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# ==========================================================================
