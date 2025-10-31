locals {

  iam_policies_filter = distinct(flatten([
    var.options.enable_business_unit_kms_cmks ? ["BusinessUnitKmsCmkPolicy"] : [],
    var.options.enable_hmpps_domain ? ["HmppsDomainSecretsPolicy"] : [],
    var.options.enable_image_builder ? ["ImageBuilderLaunchTemplatePolicy"] : [],
    var.options.enable_image_builder ? ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["CloudWatchAgentServerReducedPolicy"] : [],
    var.options.enable_ec2_delius_dba_secrets_access ? ["DeliusDbaSecretsPolicy"] : [],
    var.options.enable_ec2_self_provision ? ["Ec2SelfProvisionPolicy"] : [],
    var.options.enable_s3_shared_bucket ? ["Ec2AccessSharedS3Policy"] : [],
    var.options.enable_ec2_reduced_ssm_policy ? ["SSMManagedInstanceCoreReducedPolicy"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["OracleEnterpriseManagementSecretsPolicy", "Ec2OracleEnterpriseManagedServerPolicy"] : [],
    var.options.enable_vmimport ? ["vmimportPolicy"] : [],
    var.options.enable_xsiam_s3_integration ? ["CortexXsiamS3AccessPolicy"] : [],
    "EC2Default",
    "EC2Db",
  ]))

  iam_policy_statements_in_ec2_default = flatten([
    var.options.enable_business_unit_kms_cmks ? local.iam_policy_statements_ec2.business_unit_kms_cmk : [],
    var.options.enable_ec2_cloud_watch_agent ? local.iam_policy_statements_ec2.CloudWatchAgentServerReduced : [],
    var.options.enable_ec2_self_provision ? local.iam_policy_statements_ec2.Ec2SelfProvision : [],
    var.options.enable_s3_shared_bucket ? local.iam_policy_statements_ec2.S3ReadSharedWrite : [],
    var.options.enable_ec2_reduced_ssm_policy ? local.iam_policy_statements_ec2.SSMManagedInstanceCoreReduced : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? local.iam_policy_statements_ec2.OracleEnterpriseManagedServer : [],
  ])

  oem_account_id = try(var.environment.account_ids["hmpps-oem-${var.environment.environment}"], "OemAccountNotFound")

  iam_policies = {

    # for adding policy statements which gets fed into the ec2 default policies
    EC2Default = {
      description = "Default EC2 Policy for this environment"
      statements  = local.iam_policy_statements_in_ec2_default
    }

    EC2Db = {
      description = "Default EC2 Policy for a DB in this environment"
      statements = flatten([
        local.iam_policy_statements_in_ec2_default,
        local.iam_policy_statements_ec2.OracleLicenseTracking,
        var.options.enable_s3_db_backup_bucket ? local.iam_policy_statements_ec2.S3DbBackupRead : [],
      ])
    }

    # EC2Web = {
    #   description = "EC2 Policy for a webserver"
    #   statements = flatten([
    #     ...
    #   ])
    # }

    ImageBuilderLaunchTemplatePolicy = {
      description = "Policy allowing access to image builder launch templates"
      statements  = local.iam_policy_statements_ec2.ImageBuilderLaunchTemplate
    }

    BusinessUnitKmsCmkPolicy = {
      description = "Policy allowing access to business unit wide customer managed keys"
      statements  = local.iam_policy_statements_ec2.business_unit_kms_cmk
    }

    CloudWatchAgentServerReducedPolicy = {
      description = "Same as CloudWatchAgentServerReducedPolicy but with CreateLogGroup permission removed to ensure groups are created in code"
      statements  = local.iam_policy_statements_ec2.CloudWatchAgentServerReduced
    }

    CortexXsiamS3AccessPolicy = {
      description = "Policy allowing Cortex Xsiam access to S3 buckets for log collection"
      statements  = local.iam_policy_statements_ec2.CortexXsiamS3Access
    }

    Ec2SelfProvisionPolicy = {
      description = "Permissions to allow EC2 to self provision by pulling ec2 instance, volume and tag info"
      statements  = local.iam_policy_statements_ec2.Ec2SelfProvision
    }

    Ec2AccessSharedS3Policy = {
      description = "Permissions to allow EC2 to access shared s3 bucket"
      statements  = local.iam_policy_statements_ec2.S3ReadSharedWrite
    }

    # see corresponding policy in core-shared-services-production
    # https://github.com/ministryofjustice/modernisation-platform-ami-builds/blob/main/modernisation-platform/iam.tf
    ImageBuilderS3BucketWriteAndDeleteAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-write-delete"
      statements  = local.iam_policy_statements_ec2.S3ReadSharedWriteDelete
    }

    OracleEnterpriseManagementSecretsPolicy = {
      description = "For cross account secret access identity policy"
      statements  = local.iam_policy_statements_ec2.OracleEnterpriseManagementSecrets
    }

    DeliusDbaSecretsPolicy = {
      description = "Permissions to access Delius DBA secrets in delius-core account"
      statements  = local.iam_policy_statements_ec2.DeliusDbaSecrets
    }

    HmppsDomainSecretsPolicy = {
      description = "Permissions to access secrets in hmpps-domain-services account"
      statements  = local.iam_policy_statements_ec2.HmppsDomainSecrets
    }

    # NOTE, this doesn't include GetSecretValue since the EC2 must assume
    # a separate role to get these (EC2OracleEnterpriseManagementSecretsRole)
    Ec2OracleEnterpriseManagedServerPolicy = {
      description = "Permissions required for Oracle Enterprise Managed Server"
      statements  = local.iam_policy_statements_ec2.OracleEnterpriseManagedServer
    }

    SSMManagedInstanceCoreReducedPolicy = {
      description = "AmazonSSMManagedInstanceCore minus GetParameters"
      statements  = local.iam_policy_statements_ec2.SSMManagedInstanceCoreReduced
    }

    vmimportPolicy = {
      description = "vm import permissions"
      statements = [
        {
          effect = "Allow"
          actions = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetBucketAcl"
          ],
          resources = [
            "arn:aws:s3:::*",
            "arn:aws:s3:::*/*",
            "arn:aws:s3:::*/*/*"
          ]
        },
        {
          effect = "Allow"
          actions = [
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
          ],
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "kms:CreateGrant",
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*"
          ],
          resources = ["*"]
        }
      ]
    }

  }
}
