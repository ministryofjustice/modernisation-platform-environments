locals {

  iam_policies_filter = flatten([
    var.options.enable_business_unit_kms_cmks ? ["BusinessUnitKmsCmkPolicy"] : [],
    var.options.enable_image_builder ? ["ImageBuilderLaunchTemplatePolicy"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["CloudWatchAgentServerReducedPolicy"] : [],
    var.options.enable_ec2_self_provision ? ["Ec2SelfProvisionPolicy"] : [],
    var.options.enable_shared_s3 ? ["Ec2AccessSharedS3Policy"] : [],
    var.options.enable_ec2_get_parameter ? ["Ec2GetParameterPolicy"] : [],
    var.options.enable_ec2_get_secret ? ["Ec2GetSecretPolicy"] : [],
    var.options.enable_ec2_put_parameter ? ["Ec2PutParameterPolicy"] : [],
    var.options.enable_ec2_put_secret ? ["Ec2PutSecretPolicy"] : [],
    var.options.enable_oracle_secure_web ? ["S3ListAllBucketsAndGetLocationPolicy"] : [],
    var.options.iam_policies_filter,
  ])

  iam_policies_ec2_default = flatten([
    var.options.enable_business_unit_kms_cmks ? ["BusinessUnitKmsCmkPolicy"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["CloudWatchAgentServerReducedPolicy"] : [],
    var.options.enable_ec2_self_provision ? ["Ec2SelfProvisionPolicy"] : [],
    var.options.enable_shared_s3 ? ["Ec2AccessSharedS3Policy"] : [],
    var.options.enable_ec2_get_parameter ? ["Ec2GetParameterPolicy"] : [],
    var.options.enable_ec2_get_secret ? ["Ec2GetSecretPolicy"] : [],
    var.options.enable_ec2_put_parameter ? ["Ec2PutParameterPolicy"] : [],
    var.options.enable_ec2_put_secret ? ["Ec2PutSecretPolicy"] : [],
    var.options.enable_oracle_secure_web ? ["S3ListAllBucketsAndGetLocationPolicy"] : [],
    var.options.iam_policies_ec2_default,
  ])

  iam_policies = {

    ImageBuilderLaunchTemplatePolicy = {
      description = "Policy allowing access to image builder launch templates"
      statements = [{
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
        }, {
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
      }]
    }

    BusinessUnitKmsCmkPolicy = {
      description = "Policy allowing access to business unit wide customer managed keys"
      statements = [{
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
      }]
    }

    CloudWatchAgentServerReducedPolicy = {
      description = "Same as CloudWatchAgentServerReducedPolicy but with CreateLogGroup permission removed to ensure groups are created in code"
      statements = [{
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
        }, {
        effect = "Deny"
        actions = [
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
        }, {
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        resources = ["arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"]
      }]
    }

    Ec2SelfProvisionPolicy = {
      description = "Permissions to allow EC2 to self provision by pulling ec2 instance, volume and tag info"
      statements = [{
        effect = "Allow"
        actions = [
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
        ]
        resources = ["*"]
      }]
    }

    Ec2AccessSharedS3Policy = {
      description = "Permissions to allow EC2 to access shared s3 bucket"
      statements = [{
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        resources = concat(var.environment == "production" || var.environment == "preproduction" ? [
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
      }]
    }
    Ec2GetParameterPolicy = {
      # Not required if AmazonSSMManagedInstanceCore is being used
      description = "Permissions to allow EC2 to get SSM parameter(s)"
      statements = [{
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        resources = [
          "arn:aws:ssm:*:*:parameter:/*",
          "arn:aws:ssm:*:*:parameter:cloud-watch-config-windows",
          "arn:aws:ssm:*:*:parameter:modernisation_platform_account_id",
        ]
      }]
    }
    Ec2GetSecretPolicy = {
      # This doesn't seem to be required.  EC2s can access secrets without
      description = "Permissions to allow EC2 to get SecretManager Secrets"
      statements = [{
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecret",
        ]
        resources = ["arn:aws:secretsmanager:*:*:secret:/*"]
      }]
    }
    Ec2PutParameterPolicy = {
      description = "Permissions to allow EC2 to put parameter(s) for retrieval"
      statements = [{
        effect = "Allow"
        actions = [
          "ssm:PutParameter",
          "ssm:PutParameters",
        ]
        resources = ["arn:aws:ssm:*:*:parameter:/*"]
      }]
    }
    Ec2PutSecretPolicy = {
      description = "Permissions to allow EC2 to put SecretManager Secrets"
      statements = [{
        effect = "Allow"
        actions = [
          "secretsmanager:DeleteResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:UpdateSecret",
        ]
        resources = ["arn:aws:secretsmanager:*:*:secret:/*"]
      }]
    }

    # see corresponding policy in core-shared-services-production
    # https://github.com/ministryofjustice/modernisation-platform-ami-builds/blob/main/modernisation-platform/iam.tf
    ImageBuilderS3BucketReadOnlyAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-only"
      statements = [{
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
      }]
    }
    ImageBuilderS3BucketWriteAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-write"
      statements = [{
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
      }]
    }
    ImageBuilderS3BucketWriteAndDeleteAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-write-delete"
      statements = [{
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
      }]
    }

    S3ListAllBucketsAndGetLocationPolicy = {
      description = "Permissions to list all S3 buckets and get location.  Required for OracleSecureWeb"
      statements = [{
        effect = "Allow"
        actions = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
        ]
        resources = [
          "arn:aws:s3:::*"
        ]
      }]
    }
  }
}
