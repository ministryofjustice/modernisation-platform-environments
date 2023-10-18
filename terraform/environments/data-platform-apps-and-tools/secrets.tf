/*

These have been created in code as we do not have permission to "secretsmanager:CreateSecret"

*/

resource "aws_secretsmanager_secret" "openmetadata_entra_id_client_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "openmetadata/entra-id/client-id"
}

resource "aws_secretsmanager_secret" "openmetadata_entra_id_tenant_id" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name = "openmetadata/entra-id/tenant-id"
}