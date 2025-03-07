### [TODO] REplace resource ARNs with a parameter
resource "aws_iam_policy" "tableau-s3-backup" {
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
            "Resource": "arn:aws:s3:::yjaf-prod-tableau-backups/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::yjaf-prod-tableau-backups"
        }
    ]
 })
}

resource "aws_iam_role" "ec2-tableau-role" {
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
        key3 = aws_iam_policy.tableau-s3-backup.arn
    }
}

#attach policies 
resource "aws_iam_role_policy_attachment" "yjb-postgres-secret" {
    for_each = local.policy_arns

    role       = aws_iam_role.ec2-tableau-role.name
    policy_arn = each.value
}