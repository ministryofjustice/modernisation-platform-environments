## Policy for access to the s3 bucket for Tableau backups
resource "aws_iam_policy" "tableau_s3_backup" {
  name        = "tableau-backup-to-s3"
  description = "Enable Tableau Server instance to store backups in s3 bucket <env>-tableau-backups"
  policy = jsonencode({
 
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "${local.s3_tableau_backup}/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": local.s3_tableau_backup
        }
    ]
 })
}

#create a policy to all management instance to download files from the install-files bucket
resource "aws_iam_policy" "read_s3_install_software" {
  name        = "read_s3_install_software"
  description = "Use to enable ec2 Instances to retrieve software from S3 bucket <enviroment>-install-files"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ],
        "Resource" : ["arn:aws:s3:::${var.project_name}-${var.environment}-install-files/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-install-files"
        ]
      }
    ]
  })

  tags = local.all_tags
}

## Policy to enable reading of the Datadog API Key
resource "aws_iam_policy" "datadog_api_read" {
  name        = "datadog-api-key-read"
  description = "Policy to alow reading of the DataDog API Key from Secrets Manager"
  policy = jsonencode({
 
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": var.datadog_api_key_arn
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": var.datadog_api_key_arn
        }
    ]
 })
}

resource "aws_iam_role" "ec2_tableau_role" {
  name               = "ec2-tableau-role"
  description        = "Provide the EC2 Tablerau instances with the permissins needed for correct operation."
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

## [TODO] Add policies PutRetentionPolicy, s3-write-sbom-policy, S3Download when they exist
locals {
    policy_arns = {
        key1 = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        key2 = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        key3 = aws_iam_policy.tableau_s3_backup.arn
        key4 = aws_iam_policy.datadog_api_read.arn
        key5 = aws_iam_policy.read_s3_install_software.arn
    }
}

#attach policies 
resource "aws_iam_role_policy_attachment" "yjb-postgres-secret" {
    for_each = local.policy_arns

    role       = aws_iam_role.ec2_tableau_role.name
    policy_arn = each.value
}