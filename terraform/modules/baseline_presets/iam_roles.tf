locals {

  iam_roles_filter = distinct(flatten([
    var.options.enable_hmpps_domain ? ["EC2HmppsDomainSecretsRole"] : [],
    var.options.enable_ec2_delius_dba_secrets_access ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
    var.options.enable_image_builder ? ["EC2ImageBuilderDistributionCrossAccountRole"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
    try(length(var.options.cloudwatch_metric_oam_links), 0) != 0 ? ["CloudWatch-CrossAccountSharingRole"] : [],
    var.options.enable_xsiam_s3_integration ? ["CortexXsiamS3AccessRole"] : [],
    var.options.enable_vmimport ? ["vmimport"] : [],
  ]))

  iam_roles = {
    # prereq: ImageBuilderLaunchTemplatePolicy and BusinessUnitKmsCmkPolicy 
    # policies must be included in iam_policies
    EC2ImageBuilderDistributionCrossAccountRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "AWS"
          identifiers = [var.environment.account_root_arns["core-shared-services-production"]]
        }
      }]
      policy_attachments = [
        "arn:aws:iam::aws:policy/Ec2ImageBuilderCrossAccountDistributionAccess",
        "ImageBuilderLaunchTemplatePolicy",
        "BusinessUnitKmsCmkPolicy",
      ]
    }

    # allow EC2 instance profiles ability to assume this role
    EC2OracleEnterpriseManagementSecretsRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "AWS"
          identifiers = ["*"]
        }
        conditions = [{
          test     = "ForAnyValue:ArnLike"
          variable = "aws:PrincipalArn"
          values = [
            "arn:aws:iam::${var.environment.account_id}:role/ec2-*",
          ]
        }]
      }]
      policy_attachments = flatten([
        var.options.enable_ec2_oracle_enterprise_managed_server ? ["OracleEnterpriseManagementSecretsPolicy"] : [],
        var.options.enable_ec2_delius_dba_secrets_access ? ["DeliusDbaSecretsPolicy"] : [],
        "BusinessUnitKmsCmkPolicy",
      ])
    }

    # allow EC2 instance profiles ability to assume this role
    EC2HmppsDomainSecretsRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "AWS"
          identifiers = ["*"]
        }
        conditions = [{
          test     = "ForAnyValue:ArnLike"
          variable = "aws:PrincipalArn"
          values = [
            "arn:aws:iam::${var.environment.account_id}:role/ec2-*",
          ]
        }]
      }]
      policy_attachments = [
        "HmppsDomainSecretsPolicy",
        "BusinessUnitKmsCmkPolicy",
      ]
    }

    CloudWatch-CrossAccountSharingRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type = "AWS"
          identifiers = [
            for identifier in coalesce(var.options.cloudwatch_metric_oam_links, []) : var.environment.account_root_arns[identifier]
          ]
        }
      }]
      policy_attachments = [
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
        "arn:aws:iam::aws:policy/CloudWatchAutomaticDashboardsAccess",
        "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
      ]
    }

    # Taken from https://docs-cortex.paloaltonetworks.com/r/Cortex-XDR/Cortex-XDR-Pro-Administrator-Guide/Create-an-Assumed-Role
    CortexXsiamS3AccessRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "AWS"
          identifiers = [var.environment.account_ids["cortex_account_id"]]
        }
        conditions = [{
          test     = "StringEquals"
          variable = "sts:ExternalId"
          values   = ["/xsiam/iam_role_external_id"] # baseline looks up from SSM param
        }]
      }]
      policy_attachments = [
        "CortexXsiamS3AccessPolicy"
      ]
    }

    vmimport = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "Service"
          identifiers = ["vmie.amazonaws.com"]
        }
        conditions = [{
          test     = "StringEquals"
          variable = "sts:Externalid"
          values = [
            "vmimport",
          ]
        }]
      }]
      policy_attachments = [
        "vmimportPolicy",
      ]
    }
  }

  iam_service_linked_roles = {
    "autoscaling.amazonaws.com" = {}
  }
}
