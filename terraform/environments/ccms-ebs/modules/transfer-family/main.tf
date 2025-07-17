#--Transfer Service Webapp
resource "awscc_transfer_web_app" "this" {
  identity_provider_details = {
    instance_arn = tolist(data.aws_ssoadmin_instances.entra.identity_store_ids)[0]
    role = aws_iam_role.transfer.arn
  }
}
