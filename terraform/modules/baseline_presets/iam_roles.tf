locals {

  iam_roles_filter = distinct(flatten([
    var.options.enable_azure_sas_token ? ["SasTokenRotatorRole"] : [],
    var.options.enable_hmpps_domain ? ["EC2HmppsDomainSecretsRole"] : [],
    var.options.enable_ec2_delius_dba_secrets_access ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
    var.options.enable_image_builder ? ["EC2ImageBuilderDistributionCrossAccountRole"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
    var.options.enable_observability_platform_monitoring ? ["observability-platform"] : [],
    var.options.enable_ebs_performance_monitoring ? ["EBSPerformanceMonitoringRole"] : [],
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
          identifiers = ["core-shared-services-production"]
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

    # allow Observability Plaform read-only access to Cloudwatch metrics
    observability-platform = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type        = "AWS"
          identifiers = ["observability-platform-development"]
        }
      }]
      policy_attachments = [
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
      ]
    }

    # allow SSM to call AWS services for EBS Performance Metrics
    EBSPerformanceMonitoringRole = {
      assume_role_policy = [{
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals = {
          type = "AWS"
          identifiers = ["*"]
        }
      }]
      policy_attachments = [
        "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/CloudWatchFullAccess",
      ]
    }

    SasTokenRotatorRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals = {
          type        = "Federated"
          identifiers = ["arn:aws:iam::${var.environment.account_id}:oidc-provider/token.actions.githubusercontent.com"]
        }
        conditions = [
          {
            test     = "StringEquals"
            values   = ["sts.amazonaws.com"]
            variable = "token.actions.githubusercontent.com:aud"
          },
          {
            test     = "StringLike"
            values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:ref:refs/heads/main"]
            variable = "token.actions.githubusercontent.com:sub"
          },
        ]
      }]
      policy_attachments = [
        "SasTokenRotatorPolicy",
      ]
    }
  }

  iam_service_linked_roles = {
    "autoscaling.amazonaws.com" = {}
  }
}
