// SSM parameter to store local.domain as AppUrl
resource "aws_ssm_parameter" "app_url" {
  name   = "/${var.networking[0].application}/environment/app-url"
  type   = "SecureString"
  value  = "https://${local.app_url}/"
  key_id = data.aws_kms_key.general_shared.arn
}
