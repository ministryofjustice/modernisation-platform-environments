# Allow assume role access for obtaining the OEM Agent registration secret during plan/apply
locals {

  agentreg_assume_role_principals = {
    development = [
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-development}:root"
    ]
    test = [
    ]
    preproduction = [
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-preproduction}:root"
    ]
    production = [
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-production}:root"
    ]
  }

  agentreg_assume_role_account_ids = {
    development = [
      "${module.environment.account_ids.delius-iaps-development}"
    ]
    test = [
    ]
    preproduction = [
      "${module.environment.account_ids.delius-iaps-preproduction}"
    ]
    production = [
      "${module.environment.account_ids.delius-iaps-production}"
    ]
  }
}

  data "aws_iam_policy_document" "oem-agentreg-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = local.agentreg_assume_role_principals[local.environment]
    }
  }
}

resource "aws_iam_role" "oem-agentreg-read-access" {
  name                 = "oem-agentreg-read-access"
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.oem-agentreg-assume-role.json

  tags = local.tags
}

data "aws_iam_policy_document" "oem-agentreg-read-access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = length(local.agentreg_assume_role_account_ids[local.environment]) > 0 ? [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${local.agentreg_assume_role_account_ids[local.environment][0]}:secret:/oracle/oem/shared-passwords*"
    ] : []
  }
}
resource "aws_iam_policy" "oem-agentreg-read-access" {
  name        = "OEMAgentRegSecretRead"
  description = "Limited Read Access in OEM Account for accessing OEM Agent Registration Secret"
  policy      = data.aws_iam_policy_document.oem-agentreg-read-access.json
}

resource "aws_iam_role_policy_attachment" "oem-agentreg-read-access" {
  role       = aws_iam_role.oem-agentreg-read-access.id
  policy_arn = aws_iam_policy.oem-agentreg-read-access.arn
}