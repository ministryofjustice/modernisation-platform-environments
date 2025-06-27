# -------------------------------------------------------------
# IAM roles and policies used to run the data validation glue job
# -------------------------------------------------------------
resource "aws_iam_role" "dms_dv_glue_job_iam_role" {
  name               = "dms-dv-glue-job-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

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

resource "aws_iam_role_policy_attachment" "dms_dv_glue_job_iam_role_glue_service_role_policy_attachment" {
  role       = aws_iam_role.dms_dv_glue_job_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "dms_dv_glue_job_iam_role_rds_read_only_access_policy_attachment" {
  role       = aws_iam_role.dms_dv_glue_job_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy" "dms_dv_glue_job_iam_role_s3_policy" {
  name   = "DV-S3-Policies"
  role   = aws_iam_role.dms_dv_glue_job_iam_role.name
  policy = data.aws_iam_policy_document.dms_dv_s3_iam_policy_document.json
}

resource "aws_iam_role_policy" "dms_dv_glue_job_iam_role_athena_policy" {
  name   = "DV-Athena-Policies"
  role   = aws_iam_role.dms_dv_glue_job_iam_role.name
  policy = data.aws_iam_policy_document.dms_dv_athena_iam_policy_document.json
}

# -------------------------------------------------------------
# IAM roles and policies used to run the glue-notebook
# -------------------------------------------------------------
resource "aws_iam_role" "glue_notebook_iam_role" {
  name               = "glue-notebook-role-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having Glue-Notebook execution policies",
    }
  )
}

resource "aws_iam_role_policy_attachment" "glue_notebook_iam_role_glue_service_notebook_role_policy_attachment" {
  role       = aws_iam_role.glue_notebook_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceNotebookRole"
}

resource "aws_iam_role_policy_attachment" "glue_notebook_iam_role_glue_session_user_restricted_notebook_service_role_policy_attachment" {
  role       = aws_iam_role.glue_notebook_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AwsGlueSessionUserRestrictedNotebookServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_notebook_iam_role_rds_read_only_access_policy_attachment" {
  role       = aws_iam_role.glue_notebook_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "glue_notebook_iam_role_s3_read_only_access_policy_attachment" {
  role       = aws_iam_role.glue_notebook_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "glue_notebook_iam_role_dms_dv_policy" {
  name   = "DV-Athena-Policies"
  role   = aws_iam_role.glue_notebook_iam_role.name
  policy = data.aws_iam_policy_document.dms_dv_athena_iam_policy_document.json
}

resource "aws_iam_role_policy" "glue_notebook_iam_role_ec2_policy" {
  name   = "Notebook-EC2-Policies"
  role   = aws_iam_role.glue_notebook_iam_role.name
  policy = data.aws_iam_policy_document.glue_notebook_ec2_iam_policy_document.json
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
            "Sid": "NotebookAllowActions4",
            "Effect": "Allow",
            "Action": [
                "glue:TagResource",
                "glue:UntagResource"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "NotebookDenyActions",
            "Effect": "Deny",
            "Action": [
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

# -------------------------------------------------------------
# IAM roles and policies used to run the Glue Migration and Validation job
# -------------------------------------------------------------

resource "aws_iam_role" "glue_mig_and_val_iam_role" {
  name               = "glue-mig-and-val-iam-role-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

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

resource "aws_iam_role_policy_attachment" "glue_mig_and_val_iam_role_glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_mig_and_val_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_mig_and_val_iam_role_rds_read_only_access_policy_attachment" {
  role       = aws_iam_role.glue_mig_and_val_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy" "glue_mig_and_val_iam_role_dms_dv_policy" {
  name   = "Migration-Validation-S3-Policies"
  role   = aws_iam_role.glue_mig_and_val_iam_role.name
  policy = data.aws_iam_policy_document.glue_mig_and_val_s3_iam_policy_document.json
}

resource "aws_iam_role_policy" "glue_mig_and_val_iam_role_ec2_policy" {
  name   = "DV-Athena-Policies"
  role   = aws_iam_role.glue_mig_and_val_iam_role.name
  policy = data.aws_iam_policy_document.dms_dv_athena_iam_policy_document.json
}
