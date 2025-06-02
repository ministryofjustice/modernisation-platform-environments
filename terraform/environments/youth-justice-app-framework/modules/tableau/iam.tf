## Policy for access to the s3 bucket for Tableau backups
resource "aws_iam_policy" "tableau_s3_backup" {
  name        = "tableau-backup-to-s3"
  description = "Enable Tableau Server instance to store backups in s3 bucket <env>-tableau-backups"
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : "${local.s3_tableau_backup}/*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : local.s3_tableau_backup
      }
    ]
  })
}


## Policy to enable reading of the Datadog API Key
resource "aws_iam_policy" "datadog_api_read" {
  name        = "datadog-api-key-read"
  description = "Policy to alow reading of the DataDog API Key from Secrets Manager"
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : ["arn:aws:ec2:eu-west-2:*:instance/*"]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue"
        "Resource" : var.datadog_api_key_arn
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : "kms:Decrypt"
        "Resource" : var.kms_key_arn
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
  }
}

#attach policies 
resource "aws_iam_role_policy_attachment" "tableau" {
  for_each = local.policy_arns

  role       = aws_iam_role.ec2_tableau_role.name
  policy_arn = each.value
}