resource "aws_ssm_parameter" "cortex_account_id" {
  #checkov:skip=CKV2_AWS_34: "Parameter is not sensitive; account ID is publicly available."
  count = local.create_resources ? 1 : 0
  lifecycle {
    ignore_changes = [insecure_value]
  }
  description    = "Account ID for Palo Alto Cortex XSIAM cross-account role."
  name           = "cortex_account_id"
  type           = "String"
  insecure_value = "Placeholder"
  tags           = local.tags
}

# Azure Entra ID configuration for CloudFront authentication
resource "aws_ssm_parameter" "entra_tenant_id" {
  #checkov:skip=CKV2_AWS_34: "Tenant ID is not sensitive"
  count = local.create_resources ? 1 : 0
  lifecycle {
    ignore_changes = [insecure_value]
  }
  description    = "Azure Entra ID Tenant ID for WorkSpaces Web authentication"
  name           = "entra_tenant_id"
  type           = "String"
  insecure_value = "Placeholder"
  tags           = local.tags
}

resource "aws_ssm_parameter" "entra_client_id" {
  #checkov:skip=CKV2_AWS_34: "Client ID is not sensitive"
  count = local.create_resources ? 1 : 0
  lifecycle {
    ignore_changes = [insecure_value]
  }
  description    = "Azure Entra ID Application (Client) ID for WorkSpaces Web authentication"
  name           = "entra_client_id"
  type           = "String"
  insecure_value = "Placeholder"
  tags           = local.tags
}

# Data sources to read SSM parameters
data "aws_ssm_parameter" "entra_tenant_id" {
  count = local.create_resources ? 1 : 0
  name  = aws_ssm_parameter.entra_tenant_id[0].name
}

data "aws_ssm_parameter" "entra_client_id" {
  count = local.create_resources ? 1 : 0
  name  = aws_ssm_parameter.entra_client_id[0].name
}