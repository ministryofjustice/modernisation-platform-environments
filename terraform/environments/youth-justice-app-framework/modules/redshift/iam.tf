#Create a role for Redshift
#trusted entity is redshift, 
resource "aws_iam_role" "redshift" {
  name               = "Redshift-Serverless-Service-Role"
  description        = "Main Service Role, for Administration, Scheduling, etc."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
      "Action": "sts:AssumeRole",
      "Principal": {
          "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow"
      }
  ]
}
EOF
}

#attach policies AmazonRedshiftFullAccess
resource "aws_iam_role_policy_attachment" "redshift_full_access" {
  role       = aws_iam_role.redshift.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}


#### Redshift-Serverless-YCS-Team Role ####

#create a policy to enable reading of the rotated postgres secret.
resource "aws_iam_policy" "rds-aurora-postgres-secret" {
  name        = "rds-aurora-postgres-secret"
  description = "Enables retrieval of the RDS Postgres secret."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AccessSecret",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",

        ],
        "Resource" : [
          var.rds_redshift_secret_arns[0],
          var.rds_redshift_secret_arns[1]
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AccessSecretKey",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : var.kms_key_arn
      }
    ]
  })
}

#Policy to enable access to the reddshift s3 bucket for YCJ reporting
#TODO Note in S3 migration Inventory says this bucket is no longer used.
resource "aws_iam_policy" "redshift-ycs-reporting-s3" {
  name        = "redshift-serverless-ycs-reporting"
  description = "Enables access to YCS s3 reporting buckets."
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject"
        ],
        "Resource" : [
          local.s3-redshift-ycs-reporting-arn,
          "${local.s3-redshift-ycs-reporting-arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ycs-team" {
  name               = "Redshift-Serverless-YCS-Team"
  description        = "Role for working with YCS resources, such as YCS working area bucket and existing PostgreSQL databases."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "redshift.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

#attach policies for postgres secret
resource "aws_iam_role_policy_attachment" "postgres-secret" {
  role       = aws_iam_role.ycs-team.name
  policy_arn = aws_iam_policy.rds-aurora-postgres-secret.arn
}


#attach policies AmazonRedshift s3 access
resource "aws_iam_role_policy_attachment" "ycs-postgres-s3" {
  role       = aws_iam_role.ycs-team.name
  policy_arn = aws_iam_policy.redshift-ycs-reporting-s3.arn
}

#### redshift-serverless-yjb-reporting-moj_ap Role ####

#Policy to enable access to the reddshift s3 bucket for YCJ reporting
#TODO replace bucket arn with variable
resource "aws_iam_policy" "redshift-yjb-reporting-moj-s3" {
  name        = "redshift-serverless-yjb-reporting-moj_ap"
  description = "Enables access to YJB s3 reporting buckets."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          local.s3-redshift-yjb-reporting-arn,
          "${local.s3-redshift-yjb-reporting-arn}/moj_ap/*",
          "${local.s3-redshift-yjb-reporting-arn}/landing/*"
        ]
      }
    ]
  })
}

## TODO replace role arn with a variable
resource "aws_iam_role" "yjb-moj-team" {
  name        = "redshift-serverless-yjb-reporting-moj_ap"
  description = "Allows Redshift clusters, Events and Data Science roles to call AWS services on your behalf."
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "redshift.amazonaws.com",
            "events.amazonaws.com"
          ],
          AWS = [
            var.data_science_role,
            var.reports_admin_role
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#attach policies AmazonEventBridgeFullAccess
resource "aws_iam_role_policy_attachment" "yjb-moj-event-bridge" {
  role       = aws_iam_role.yjb-moj-team.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

#attach policies AmazonRedshiftFullAccess
resource "aws_iam_role_policy_attachment" "yjb-moj-redshift" {
  role       = aws_iam_role.yjb-moj-team.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}
#attach policies AmazonRedshiftFullAccess
resource "aws_iam_role_policy_attachment" "yjb-moj-S3" {
  role       = aws_iam_role.yjb-moj-team.name
  policy_arn = aws_iam_policy.redshift-yjb-reporting-moj-s3.arn
}


#### Redshift-Serverless-YJB-Team Role ####

#Policy to enable access to the reddshift s3 bucket for YJB reporting
resource "aws_iam_policy" "redshift-yjb-reporting-s3" {
  name        = "redshift-serverless-yjb-reporting"
  description = "Enables access to YJB s3 reporting buckets."
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject"
        ],
        "Resource" : [
          local.s3-redshift-yjb-reporting-arn,
          "${local.s3-redshift-yjb-reporting-arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "yjb-team" {
  name               = "Redshift-Serverless-YJB-Team"
  description        = "Role to working with YJB resources, such as YJB working area bucket and existing PostgreSQL databases."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "redshift.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

#attach policies AmazonRedshiftFullAccess
resource "aws_iam_role_policy_attachment" "yjb-postgres-secret" {
  role       = aws_iam_role.yjb-team.name
  policy_arn = aws_iam_policy.rds-aurora-postgres-secret.arn
}


#attach policies AmazonRedshiftFullAccess
resource "aws_iam_role_policy_attachment" "yjb-redshift-s3" {
  role       = aws_iam_role.yjb-team.name
  policy_arn = aws_iam_policy.redshift-yjb-reporting-s3.arn
}

