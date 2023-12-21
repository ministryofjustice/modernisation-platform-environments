locals {

  iam_policy_statements = {
    ImageBuilderLaunchTemplate = [
      {
        sid = "ImageBuilderLaunchTemplate1"
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
        sid = "ImageBuilderLaunchTemplate2"
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
        sid = "BusinessUnitKmsCmk"
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
        sid = "CloudWatchAgentServerReduced"
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
        sid = "DenyCreateLogGroup"
        effect = "Deny"
        actions = [
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
      },
      {
        sid = "AllowCloudwatchSSMParams"
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

    Ec2SelfProvision = [
      {
        sid = "Ec2SelfProvision"
        effect = "Allow"
        actions = [
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
        ]
        resources = ["*"]
      }
    ]

    S3ReadSharedWrite = [
      {
        sid = "S3ReadSharedWrite"
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        resources = concat(var.environment.environment == "production" || var.environment.environment == "preproduction" ? [
          "arn:aws:s3:::prodpreprod-${var.environment.application_name}-*/*",
          "arn:aws:s3:::prodpreprod-${var.environment.application_name}-*"
          ] : [
          "arn:aws:s3:::devtest-${var.environment.application_name}-*/*",
          "arn:aws:s3:::devtest-${var.environment.application_name}-*"
          ], [
          "arn:aws:s3:::ec2-image-builder-*/*",
          "arn:aws:s3:::ec2-image-builder-*",
          "arn:aws:s3:::*-software*/*",
          "arn:aws:s3:::*-software*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
          "arn:aws:s3:::mod-platform-image-artefact-bucket*",
          "arn:aws:s3:::modernisation-platform-software*/*",
          "arn:aws:s3:::modernisation-platform-software*"
        ])
      }
    ]

    # see corresponding policy in core-shared-services-production
    # https://github.com/ministryofjustice/modernisation-platform-ami-builds/blob/main/modernisation-platform/iam.tf
    S3ReadShared = [
      {
        sid = "S3ReadShared"
        effect = "Allow"
        actions = [
          "s3:GetObject",
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
        sid = "S3ReadSharedWriteLimited"
        effect = "Allow"
        actions = [
          "s3:GetObject",
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
        sid = "S3ReadSharedWriteDelete"
        effect = "Allow"
        actions = [
          "s3:GetObject",
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
    
    SecretsCrossAccount = [
      {
        sid = "SecretsCrossAccount"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
        ]
        resources = ["*"]
      }
    ]
    
    # NOTE, this doesn't include GetSecretValue since the EC2 must assume
    # a separate role to get these (EC2OracleEnterpriseManagementSecretsRole)
    OracleEnterpriseManagedServer = [
      {
        sid = "S3ListLocation"
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
        sid = "SSMGetAccountIds"
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
    
    OracleEnterpriseManager = [
      {
        sid = "S3ListLocation"
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
        sid = "SecretsmanagerReadWriteOracle"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
        ]
        resources = [
          "arn:aws:secretsmanager:*:*:secret:/oracle/*",
        ]
      },
      {
        sid = "SSMReadAccountIdsOracle"
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        resources = [
          "arn:aws:ssm:*:*:parameter/account_ids",
          "arn:aws:ssm:*:*:parameter/oracle/*",
        ]
      },
      {
        sid = "SSMWriteOracle"
        effect = "Allow"
        actions = [
          "ssm:PutParameter",
          "ssm:PutParameters",
        ]
        resources = [
          "arn:aws:ssm:*:*:parameter/oracle/*",
        ]
      }
    ]
    
    OracleLicenseTracking = [
      {
        sid = "OracleLicenseTracking"
        effect = "Allow"
        actions = [
          "s3:PutObject",
          "s3:GetObject",
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
        sid = "SSMManagedSSM"
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
        sid = "SSMManagedSSMMessages"
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
        sid = "SSMManagedEC2Messages"
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

    # for image builder
    S3ReadWriteCoreSharedServicesProduction = [
      {
        sid = "S3ReadWriteCoreSharedServicesProduction"
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            var.environment.account_root_arns["core-shared-services-production"]
          ]
        }
      }
    ]

    S3ReadAllEnvironments = [
      {
        sid = "S3ReadAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            for account_name in var.environment.account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadOnlyPreprod = [
      {
        sid = "S3ReadOnlyPreprod"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            var.environment.account_root_arns["${var.environment.application_name}-preproduction"]
          ]
        }
      }
    ]

    S3ReadWriteAllEnvironments = [
      {
        sid = "S3ReadWriteAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadProdPreprod = [
      {
        sid = "S3ReadProdPreprod"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.prodpreprod_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteProdPreprod = [
      {
        sid = "S3ReadWriteProdPreprod"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.prodpreprod_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteDeleteAllEnvironments = [
      {
        sid = "S3ReadWriteDeleteAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadDevTest = [
      {
        sid = "S3ReadDevTest"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.devtest_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteDeleteDevTest = [
      {
        sid = "S3ReadWriteDeleteDevTest"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.devtest_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadDev = [
      {
        sid = "S3ReadDev"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            var.environment.account_root_arns["${var.environment.application_name}-development"]
          ]
        }
      }
    ]

    S3Read = [
      {
        sid = "S3Read"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
        ]
      }
    ]
    S3Write = [
      {
        sid = "S3Write"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:RestoreObject",
        ]
      }
    ]
    S3ReadWriteDelete = [
      {
        sid = "S3ReadWriteDelete"
        effect = "Allow"
        actions = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
      }
    ]
  }

}
