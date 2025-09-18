locals {

  iam_policy_statements_ec2 = {
    ImageBuilderLaunchTemplate = [
      {
        sid    = "ImageBuilderLaunchTemplate1"
        effect = "Allow"
        actions = [
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate"
        ]
        resources = ["*"]
        conditions = [{
          test     = "StringEquals"
          variable = "aws:ResourceTag/CreatedBy"
          values   = ["EC2 Image Builder"]
        }]
      },
      {
        sid    = "ImageBuilderLaunchTemplate2"
        effect = "Allow"
        actions = [
          "ec2:DescribeLaunchTemplates"
        ]
        resources = ["arn:aws:ec2:*:*:launch-template/*"]
        conditions = [{
          test     = "StringEquals"
          variable = "aws:ResourceTag/CreatedBy"
          values   = ["EC2 Image Builder"]
        }]
      }
    ]

    business_unit_kms_cmk = [
      {
        sid    = "BusinessUnitKmsCmk"
        effect = "Allow"
        actions = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        resources = [
          var.environment.kms_keys["ebs"].arn,
          var.environment.kms_keys["general"].arn
        ]
      }
    ]

    CloudWatchAgentServerReduced = [ # "Same as CloudWatchAgentServerReduced but with CreateLogGroup permission removed to ensure groups are created in code"
      {
        sid    = "CloudWatchAgentServerReduced"
        effect = "Allow"
        actions = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
      },
      {
        sid    = "DenyCreateLogGroup"
        effect = "Deny"
        actions = [
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
      },
      {
        sid    = "AllowCloudwatchSSMParams"
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        resources = [
          "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*",
          "arn:aws:ssm:*:*:parameter/cloud-watch-config-windows",
        ]
      }
    ]

    CortexXsiamS3Access = [
      {
        sid    = "CortexXsiamSQS"
        effect = "Allow"
        actions = [
          "sqs:ChangeMessageVisibility",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues"
        ]
        resources = [
          "arn:aws:sqs:::*log*",
        ]
      },
      {
        sid     = "CortexXsiamS3"
        effect  = "Allow"
        actions = ["s3:GetObject"]
        resources = [
          "arn:aws:s3:::*log*",
          "arn:aws:s3:::*log*/*",
        ]
      },
      {
        sid    = "CortexXsiamSQSKms"
        effect = "Allow"
        actions = [
          "kms:Decrypt",
        ]
        resources = [
          var.environment.kms_keys["ebs"].arn,
          var.environment.kms_keys["general"].arn,
          var.environment.kms_keys["s3"].arn
        ]
      }
    ]

    Ec2SelfProvision = [
      {
        sid    = "Ec2SelfProvision"
        effect = "Allow"
        actions = [
          "autoscaling:CompleteLifecycleAction",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
        ]
        resources = ["*"]
      }
    ]

    S3ReadSharedWrite = [
      {
        sid    = "S3ReadSharedWrite"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        resources = [
          "arn:aws:s3:::${local.s3_environment_specific.shared_bucket_name}*/*",
          "arn:aws:s3:::${local.s3_environment_specific.shared_bucket_name}*",
          "arn:aws:s3:::ec2-image-builder-*/*",
          "arn:aws:s3:::ec2-image-builder-*",
          "arn:aws:s3:::*-software*/*",
          "arn:aws:s3:::*-software*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*",
          "arn:aws:s3:::modernisation-platform-software*/*",
          "arn:aws:s3:::modernisation-platform-software*"
        ]
      }
    ]

    # see corresponding policy in core-shared-services-production
    # https://github.com/ministryofjustice/modernisation-platform-ami-builds/blob/main/modernisation-platform/iam.tf
    S3ReadShared = [
      {
        sid    = "S3ReadShared"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
        ]
        resources = [
          "arn:aws:s3:::ec2-image-builder-*/*",
          "arn:aws:s3:::ec2-image-builder-*",
          "arn:aws:s3:::*-software*/*",
          "arn:aws:s3:::*-software*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*",
          "arn:aws:s3:::modernisation-platform-software*/*",
          "arn:aws:s3:::modernisation-platform-software*"
        ]
      }
    ]

    S3ReadSharedWriteLimited = [
      {
        sid    = "S3ReadSharedWriteLimited"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        resources = [
          "arn:aws:s3:::ec2-image-builder-*/*",
          "arn:aws:s3:::ec2-image-builder-*",
          "arn:aws:s3:::*-software*/*",
          "arn:aws:s3:::*-software*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*",
          "arn:aws:s3:::modernisation-platform-software*/*",
          "arn:aws:s3:::modernisation-platform-software*"
        ]
      }
    ]

    S3ReadSharedWriteDelete = [
      {
        sid    = "S3ReadSharedWriteDelete"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
        ]
        resources = [
          "arn:aws:s3:::ec2-image-builder-*/*",
          "arn:aws:s3:::ec2-image-builder-*",
          "arn:aws:s3:::*-software*/*",
          "arn:aws:s3:::*-software*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*",
          "arn:aws:s3:::modernisation-platform-software*/*",
          "arn:aws:s3:::modernisation-platform-software*"
        ]
      }
    ]

    OracleEnterpriseManagementSecrets = [
      {
        sid    = "OracleEnterpriseManagementSecrets"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = [
          "arn:aws:secretsmanager:*:${var.environment.cross_account_secret_account_ids.hmpps_oem}:secret:/oracle/oem/shared-*",
          "arn:aws:secretsmanager:*:${var.environment.cross_account_secret_account_ids.hmpps_oem}:secret:/oracle/database/*/shared-*",
        ]
      }
    ]

    DeliusDbaSecrets = [
      {
        sid    = "OracleEnterpriseManagementSecrets"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = [
          "arn:aws:secretsmanager:*:${var.environment.cross_account_secret_account_ids.delius}:secret:*db-dba-*",
          "arn:aws:secretsmanager:*:${var.environment.cross_account_secret_account_ids.delius_mis}:secret:*db-dba-*",
        ]
      }
    ]

    HmppsDomainSecrets = [
      {
        sid    = "HmppsDomainSecrets"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = [
          "arn:aws:secretsmanager:*:${var.environment.cross_account_secret_account_ids.hmpps_domain}:secret:/microsoft/AD/*/shared-*",
        ]
      }
    ]

    # NOTE, this doesn't include GetSecretValue since the EC2 must assume
    # a separate role to get these (EC2OracleEnterpriseManagementSecretsRole)
    OracleEnterpriseManagedServer = [
      {
        sid    = "S3ListLocation"
        effect = "Allow"
        actions = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
        ]
        resources = [
          "arn:aws:s3:::*"
        ]
      },
      {
        sid    = "SSMGetAccountIds"
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        resources = [
          "arn:aws:ssm:*:*:parameter/account_ids",
        ]
      }
    ]

    OracleLicenseTracking = [
      {
        sid    = "OracleLicenseTracking"
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        resources = [
          "arn:aws:s3:::license-manager-artifact-bucket/*",
          "arn:aws:s3:::license-manager-artifact-bucket"
        ],
      }
    ]

    SSMManagedInstanceCoreReduced = [ # AmazonSSMManagedInstanceCore minus GetParameters
      {
        sid    = "SSMManagedSSM"
        effect = "Allow"
        actions = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
        ]
        resources = ["*"]
      },
      {
        sid    = "SSMManagedSSMMessages"
        effect = "Allow"
        actions = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        resources = ["*"]
      },
      {
        sid    = "SSMManagedEC2Messages"
        effect = "Allow"
        actions = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        resources = ["*"]
      },
    ]

    S3DbBackupRead = [
      {
        sid    = "S3DbBackupRead"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
        ]
        resources = flatten([
          var.environment.environment == "production" ? [
            "arn:aws:s3:::${local.s3_environments_specific.preproduction.db_backup_bucket_name}*",
            "arn:aws:s3:::${local.s3_environments_specific.preproduction.db_backup_bucket_name}*/*",
            "arn:aws:s3:::${local.s3_environments_specific.production.db_backup_bucket_name}*",
            "arn:aws:s3:::${local.s3_environments_specific.production.db_backup_bucket_name}*/*",
          ] : [],
          var.environment.environment == "preproduction" ? [
            "arn:aws:s3:::${local.s3_environments_specific.preproduction.db_backup_bucket_name}*",
            "arn:aws:s3:::${local.s3_environments_specific.preproduction.db_backup_bucket_name}*/*",
          ] : [],
          contains(["development", "test"], var.environment.environment) ? [
            "arn:aws:s3:::${local.s3_environments_specific.development.db_backup_bucket_name}*",
            "arn:aws:s3:::${local.s3_environments_specific.development.db_backup_bucket_name}*/*",
            "arn:aws:s3:::${local.s3_environments_specific.test.db_backup_bucket_name}*",
            "arn:aws:s3:::${local.s3_environments_specific.test.db_backup_bucket_name}*/*",
          ] : [],
        ])
      }
    ]

  }

}
