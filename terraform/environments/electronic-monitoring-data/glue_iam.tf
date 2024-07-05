# IAM role used to run the data validation glue job
resource "aws_iam_role" "dms_dv_glue_job_iam_role" {
  name               = "dms-dv-glue-job-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  ]
  inline_policy {
    name   = "DV-S3-Policies"
    policy = data.aws_iam_policy_document.dms_dv_s3_iam_policy_document.json
  }

  inline_policy {
    name   = "DV-Athena-Policies"
    policy = data.aws_iam_policy_document.dms_dv_athena_iam_policy_document.json
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having Glue-Job execution policies",
    }
  )
  lifecycle {
    create_before_destroy = false
  }
}

# # IAM role used to run the glue-notebook
resource "aws_iam_role" "glue_notebook_iam_role" {
  name               = "glue-notebook-role-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceNotebookRole",
    "arn:aws:iam::aws:policy/service-role/AwsGlueSessionUserRestrictedNotebookServiceRole",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policy {
    name   = "DV-Athena-Policies"
    policy = data.aws_iam_policy_document.dms_dv_athena_iam_policy_document.json
  }

  inline_policy {
    name   = "Notebook-EC2-Policies"
    policy = data.aws_iam_policy_document.glue_notebook_ec2_iam_policy_document.json
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having Glue-Notebook execution policies",
    }
  )
}

resource "aws_iam_policy" "glue_user_restricted_notebook_service_role_iam_policy" {
  name = "glue-user-restricted-notebook-service-role-policy-tf"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NotebokAllowActions0",
            "Effect": "Allow",
            "Action": [
                "glue:CreateSession"
            ],
            "Resource": [
                "arn:aws:glue:*:*:session/*"
            ]
        },
        {
            "Sid": "NotebookAllowActions1",
            "Effect": "Allow",
            "Action": [
                "glue:StartCompletion",
                "glue:GetCompletion"
            ],
            "Resource": [
                "arn:aws:glue:*:*:completion/*"
            ]
        },
        {
            "Sid": "NotebookAllowActions2",
            "Effect": "Allow",
            "Action": [
                "glue:RunStatement",
                "glue:GetStatement",
                "glue:ListStatements",
                "glue:CancelStatement",
                "glue:StopSession",
                "glue:DeleteSession",
                "glue:GetSession"
            ],
            "Resource": [
                "arn:aws:glue:*:*:session/*"
            ]
        },
        {
            "Sid": "NotebookAllowActions3",
            "Effect": "Allow",
            "Action": [
                "glue:ListSessions"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "NotebookDenyActions",
            "Effect": "Deny",
            "Action": [
                "glue:TagResource",
                "glue:UntagResource",
                "tag:TagResources",
                "tag:UntagResources"
            ],
            "Resource": [
                "arn:aws:glue:*:*:session/*"
            ],
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:TagKeys": [
                        "owner"
                    ]
                }
            }
        },
        {
            "Sid": "PolicyStatementToAllowUserToListRoles",
            "Effect": "Allow",
            "Action": ["iam:ListRoles"],
            "Resource": "*"
        },
        {
            "Sid": "NotebookPassRole",
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::*:role/service-role/AwsGlueSessionServiceRoleUserRestrictedForNotebook*",
                "arn:aws:iam::${local.env_account_id}:role/${aws_iam_role.glue_notebook_iam_role.name}"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "glue.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

# Attach predefined IAM Policy to the Glue-Notebook Role
resource "aws_iam_role_policy_attachment" "glue_user_restricted_notebook_service_role_policy_attachment" {
  role       = aws_iam_role.glue_notebook_iam_role.name
  policy_arn = aws_iam_policy.glue_user_restricted_notebook_service_role_iam_policy.arn
}
