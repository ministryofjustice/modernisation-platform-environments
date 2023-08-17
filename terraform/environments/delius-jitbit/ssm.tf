// SSM parameter to store local.domain as AppUrl
resource "aws_ssm_parameter" "app_url" {
  name  = "/${var.networking[0].application}/environment/app-url"
  type  = "String"
  value = "https://${local.app_url}/"
}
