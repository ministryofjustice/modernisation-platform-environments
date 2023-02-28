locals {

  iam_roles_filter = flatten([
    var.options.enable_image_builder ? ["EC2ImageBuilderDistributionCrossAccountRole"] : []
  ])

  iam_roles = {
    # prereq: ImageBuilderLaunchTemplatePolicy and BusinessUnitKmsCmkPolicy 
    # policies must be included in iam_policies
    EC2ImageBuilderDistributionCrossAccountRole = {
      assume_role_policy_principals_type        = "AWS"
      assume_role_policy_principals_identifiers = ["core-shared-services-production"]
      policy_attachments = [
        "arn:aws:iam::aws:policy/Ec2ImageBuilderCrossAccountDistributionAccess",
        "ImageBuilderLaunchTemplatePolicy",
        "BusinessUnitKmsCmkPolicy"
      ]
    }
  }

  iam_service_linked_roles = {
    "autoscaling.amazonaws.com" = {}
  }
}
