######################################################################################
# IAM Roles, Policies, Attachments and Profiles for SSM, S3, Security Hub & Cloudwatch
######################################################################################

##############################################
# EC2 Roles, Policies, Attachment and Profiles
##############################################

# IAM EC2 Policy with Assume Role 

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create EC2 IAM Role
resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2-iam-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Create EC2 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}

# Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ec2_attach1" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ec2_attach2" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "production-s3-access" {
  count      = local.is-production == false ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "Prod-s3-access-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = aws_iam_policy.production-s3-access[0].arn
}

resource "aws_iam_policy_attachment" "CloudWatchAgentAdminPolicy" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "CloudWatchAgentAdminPolicy-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_policy_attachment" "CloudWatchAgentServerPolicy" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "CloudWatchAgentServerPolicy-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#####################################
# IAM Policy for Production S3 access
#####################################

resource "aws_iam_policy" "production-s3-access" {
  count       = local.is-production == false ? 1 : 0
  name        = "production-s3-access"
  path        = "/"
  description = "production-s3-access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action" : "s3:ListBucket",
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:s3:::moj-infrastructure",
        "arn:aws:s3:::moj-infrastructure/*"
      ]
    }]
  })
}

#################################
# IAM Role for SSM Patch Manager
#################################

resource "aws_iam_role" "patching_role" {
  name = "maintenance_window_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach necessary policies to the Patching role
resource "aws_iam_role_policy_attachment" "maintenance_window_task_policy_attachment" {
  role       = aws_iam_role.patching_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

####################################################
# IAM User, Policy for MGN
####################################################

#tfsec:ignore:aws-iam-no-user-attached-policies 
#tfsec:ignore:AWS273
resource "aws_iam_user" "mgn_user" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also set to ignore"
  name = "MGN-Test"
  tags = local.tags
}
#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user_policy_attachment" "mgn_attach_policy" {
  #tfsec:ignore:aws-iam-no-user-attached-policies
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationMigrationFullAccess"
}

####################################################
# IAM User, Policy, Access Key for email
####################################################

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "email" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also ignored"
  count = local.is-production == false ? 1 : 0
  name  = format("%s-%s-email_user", local.application_name, local.environment)
  tags = merge(local.tags,
    { Name = format("%s-%s-email_user", local.application_name, local.environment) }
  )
}

resource "aws_iam_access_key" "email" {
  count = local.is-production == false ? 1 : 0
  user  = aws_iam_user.email[0].name
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_user_policy" "email_policy" {
  # checkov:skip=CKV_AWS_40:"Directly attaching the policy makes more sense here"
  count  = local.is-production == false ? 1 : 0
  name   = "AmazonSesSendingAccess"
  user   = aws_iam_user.email[0].name
  policy = data.aws_iam_policy_document.email.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "email" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_356: Policy follows AWS guidance
  statement {
    actions = [
      "ses:SendRawEmail"
    ]
    resources = ["*"]
  }
}

##########################################################################################
# S3 Bucket Roles and Policies for S3 Buckets that replicate to Justice Digital S3 Buckets
##########################################################################################

#########################################################
# IAM Role & Policy for S3 Bucket Replication to DE - DEV
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_database_source_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_database_source_dev"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_database_source_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_database_source_dev"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-database-source-dev[0].arn,
          "${aws_s3_bucket.moj-database-source-dev[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::mojap-data-engineering-production-ppud-dev",
          "arn:aws:s3:::mojap-data-engineering-production-ppud-dev/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_database_source_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_database_source_dev[0].arn
}

#########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - DEV
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_dev"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_dev"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-dev[0].arn,
          "${aws_s3_bucket.moj-report-source-dev[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9",
          "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_dev[0].arn
}

#########################################################
# IAM Role & Policy for S3 Bucket Replication to DE - UAT
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_database_source_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_database_source_uat"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_database_source_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_database_source_uat"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-database-source-uat[0].arn,
          "${aws_s3_bucket.moj-database-source-uat[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::mojap-data-engineering-production-ppud-preprod",
          "arn:aws:s3:::mojap-data-engineering-production-ppud-preprod/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_database_source_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_database_source_uat[0].arn
}

#########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - UAT
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_uat"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_uat"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-uat[0].arn,
          "${aws_s3_bucket.moj-report-source-uat[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc",
          "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_uat[0].arn
}

##########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - PROD
##########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_prod"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_prod"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-prod[0].arn,
          "${aws_s3_bucket.moj-report-source-prod[0].arn}/*"

        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-9c7fd5fc774969b089e942111a7d5671",
          "arn:aws:s3:::cloud-platform-9c7fd5fc774969b089e942111a7d5671/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_prod[0].arn
}

##########################################################
# IAM Role & Policy for S3 Bucket Replication to DE - PROD
##########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_database_source_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_database_source_prod"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_database_source_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_database_source_prod"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-database-source-prod[0].arn,
          "${aws_s3_bucket.moj-database-source-prod[0].arn}/*"

        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::mojap-data-engineering-production-ppud-prod",
          "arn:aws:s3:::mojap-data-engineering-production-ppud-prod/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_database_source_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_database_source_prod[0].arn
}