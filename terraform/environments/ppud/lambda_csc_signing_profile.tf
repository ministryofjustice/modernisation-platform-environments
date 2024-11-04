##############################################################
# Signing Profiles and Lambda Code Signing Configuration (CSC)
##############################################################

# Development signing profile and lambda signing configuration

resource "aws_signer_signing_profile" "lambda_signing_profile_dev" {
  count       = local.is-development == true ? 1 : 0
  name_prefix = "grw77tzk96phtwcrceot5xlbt9veqixuyck044"
  platform_id = "AWSLambda-SHA384-ECDSA"
  depends_on  = [aws_iam_role_policy_attachment.attach_aws_signer_policy_to_aws_signer_role_dev]
  signature_validity_period {
    value = 10
    type  = "YEARS"
  }
}

resource "aws_lambda_code_signing_config" "lambda_csc_dev" {
  count       = local.is-development == true ? 1 : 0
  description = "Lambda code signing configuration for development environment"
  allowed_publishers {
    signing_profile_version_arns = [
      "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:/signing-profiles/grw77tzk96phtwcrceot5xlbt9veqixuyck04420241008100655411100000002/AHvOa02ifI"
    ]
  }
  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

# UAT signing profile and lambda signing configuration

resource "aws_signer_signing_profile" "lambda_signing_profile_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name_prefix = "ucjvuurx21fa91xmhktdde5ognhxig1vahls8z"
  platform_id = "AWSLambda-SHA384-ECDSA"
  depends_on  = [aws_iam_role_policy_attachment.attach_aws_signer_policy_to_aws_signer_role_uat]
  signature_validity_period {
    value = 10
    type  = "YEARS"
  }
}

resource "aws_lambda_code_signing_config" "lambda_csc_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  description = "Lambda code signing configuration for uat environment"
  allowed_publishers {
    signing_profile_version_arns = [
      "arn:aws:signer:eu-west-2:172753231260:/signing-profiles/ucjvuurx21fa91xmhktdde5ognhxig1vahls8z20241008084937718900000002/ZYACVFPo1R"
    ]
  }
  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

# Production signing profile and lambda signing configuration

resource "aws_signer_signing_profile" "lambda_signing_profile_prod" {
  count       = local.is-production == true ? 1 : 0
  name_prefix = "0r1ihd4swpgdxsjmfe1ibqhvdpm3zg05le4uni"
  platform_id = "AWSLambda-SHA384-ECDSA"
  depends_on  = [aws_iam_role_policy_attachment.attach_aws_signer_policy_to_aws_signer_role_prod]
  signature_validity_period {
    value = 10
    type  = "YEARS"
  }
}

resource "aws_lambda_code_signing_config" "lambda_csc_prod" {
  count       = local.is-production == true ? 1 : 0
  description = "Lambda code signing configuration for production environment"
  allowed_publishers {
    signing_profile_version_arns = [
      "arn:aws:signer:eu-west-2:817985104434:/signing-profiles/0r1ihd4swpgdxsjmfe1ibqhvdpm3zg05le4uni20241008100713396700000002/HzoPedNoUr"
    ]
  }
  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}
