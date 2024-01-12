locals {

  iam_roles_filter = flatten([
    var.options.enable_image_builder ? ["EC2ImageBuilderDistributionCrossAccountRole"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server || var.options.enable_ec2_oracle_enterprise_manager ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
    var.options.enable_observability_platform_monitoring ? ["observability-platform"] : [],
  ])

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
      policy_attachments = [
        "OracleEnterpriseManagementSecretsPolicy",
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
  }

  iam_service_linked_roles = {
    "autoscaling.amazonaws.com" = {}
  }
}
