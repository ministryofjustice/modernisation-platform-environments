locals {

  iam_roles_filter = flatten([
    var.options.enable_image_builder ? ["EC2ImageBuilderDistributionCrossAccountRole"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["EC2OracleEnterpriseManagementSecretsRole"] : [],
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
            "arn:aws:iam::${var.environment.account_id}:role/database-*",
          ]
        }]
      }]
      policy_attachments = [
        "OracleEnterpriseManagementSecretsPolicy",
        "BusinessUnitKmsCmkPolicy",
      ]
    }
  }

  iam_service_linked_roles = {
    "autoscaling.amazonaws.com" = {}
  }
}
