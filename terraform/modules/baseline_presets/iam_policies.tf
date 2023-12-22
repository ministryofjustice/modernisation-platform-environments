locals {

  iam_policies_filter = flatten([
    var.options.enable_business_unit_kms_cmks ? ["BusinessUnitKmsCmkPolicy"] : [],
    var.options.enable_image_builder ? ["ImageBuilderLaunchTemplatePolicy"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["CloudWatchAgentServerReducedPolicy"] : [],
    var.options.enable_ec2_self_provision ? ["Ec2SelfProvisionPolicy"] : [],
    var.options.enable_shared_s3 ? ["Ec2AccessSharedS3Policy"] : [],
    var.options.enable_ec2_reduced_ssm_policy ? ["SSMManagedInstanceCoreReducedPolicy"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["OracleEnterpriseManagementSecretsPolicy","Ec2OracleEnterpriseManagedServerPolicy"] : [],
    var.options.enable_ec2_oracle_enterprise_manager ? ["Ec2OracleEnterpriseManagerPolicy"] : [],
    var.options.iam_policies_filter,
    "EC2Default",
  ])

  # for adding policies - be careful not to run into the limit
  iam_policies_ec2_default = flatten([
    # "EC2Default",
    var.options.enable_ec2_reduced_ssm_policy ? [] : ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"],
    var.options.iam_policies_ec2_default,
  ])

  oem_account_id = try(var.environment.account_ids["hmpps-oem-${var.environment.environment}"], "OemAccountNotFound")

  iam_policies = {

    # for adding policy statements which gets fed into the ec2 default policies
    EC2Default = {
      description = "Default EC2 Policy for this environment"
      statements = flatten([
        var.options.enable_business_unit_kms_cmks               ? local.iam_policy_statements.business_unit_kms_cmk : [],
        var.options.enable_ec2_cloud_watch_agent                ? local.iam_policy_statements.CloudWatchAgentServerReduced : [],
        var.options.enable_ec2_self_provision                   ? local.iam_policy_statements.Ec2SelfProvision : [],
        var.options.enable_shared_s3                            ? local.iam_policy_statements.S3ReadSharedWrite : [],
        var.options.enable_ec2_reduced_ssm_policy               ? local.iam_policy_statements.SSMManagedInstanceCoreReduced : [],
        var.options.enable_ec2_oracle_enterprise_managed_server ? local.iam_policy_statements.OracleEnterpriseManagedServer : [],
        var.options.enable_ec2_oracle_enterprise_manager        ? local.iam_policy_statements.OracleEnterpriseManager : [],
        var.options.iam_policy_statements_ec2_default,
      ])
    }

    EC2Db = {
      description = "EC2 Policy for a DB"
      statements = flatten([
        local.iam_policy_statements.OracleLicenseTracking
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
      statements = local.iam_policy_statements.ImageBuilderLaunchTemplate
    }

    BusinessUnitKmsCmkPolicy = {
      description = "Policy allowing access to business unit wide customer managed keys"
      statements = local.iam_policy_statements.business_unit_kms_cmk
    }

    CloudWatchAgentServerReducedPolicy = {
      description = "Same as CloudWatchAgentServerReducedPolicy but with CreateLogGroup permission removed to ensure groups are created in code"
      statements = local.iam_policy_statements.CloudWatchAgentServerReduced
    }

    Ec2SelfProvisionPolicy = {
      description = "Permissions to allow EC2 to self provision by pulling ec2 instance, volume and tag info"
      statements = local.iam_policy_statements.Ec2SelfProvision
    }

    Ec2AccessSharedS3Policy = {
      description = "Permissions to allow EC2 to access shared s3 bucket"
      statements = local.iam_policy_statements.S3ReadSharedWrite
    }

    # see corresponding policy in core-shared-services-production
    # https://github.com/ministryofjustice/modernisation-platform-ami-builds/blob/main/modernisation-platform/iam.tf
    ImageBuilderS3BucketReadOnlyAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-only"
      statements = local.iam_policy_statements.S3ReadShared
    }
    ImageBuilderS3BucketWriteAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-write"
      statements = local.iam_policy_statements.S3ReadSharedWriteLimited
    }
    ImageBuilderS3BucketWriteAndDeleteAccessPolicy = {
      description = "Permissions to access shared ImageBuilder bucket read-write-delete"
      statements = local.iam_policy_statements.S3ReadSharedWriteDelete
    }

    OracleEnterpriseManagementSecretsPolicy = {
      description = "For cross account secret access identity policy"
      statements = local.iam_policy_statements.SecretsCrossAccount
    }

    # NOTE, this doesn't include GetSecretValue since the EC2 must assume
    # a separate role to get these (EC2OracleEnterpriseManagementSecretsRole)
    Ec2OracleEnterpriseManagedServerPolicy = {
      description = "Permissions required for Oracle Enterprise Managed Server"
      statements = local.iam_policy_statements.OracleEnterpriseManagedServer
    }

    Ec2OracleEnterpriseManagerPolicy = {
      description = "Permissions required for Oracle Enterprise Manager"
      statements = local.iam_policy_statements.OracleEnterpriseManager
    }

    SSMManagedInstanceCoreReducedPolicy = {
      description = "AmazonSSMManagedInstanceCore minus GetParameters"
      statements = local.iam_policy_statements.SSMManagedInstanceCoreReduced
    }
  }
}
