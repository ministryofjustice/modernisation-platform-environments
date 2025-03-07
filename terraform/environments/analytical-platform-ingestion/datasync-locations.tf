resource "aws_datasync_location_s3" "opg" {
  s3_bucket_arn = module.datasync_opg_bucket.s3_bucket_arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
  }

  tags = local.tags
}

resource "aws_datasync_location_smb" "opg" {
  server_hostname = "eucw4171nas012.dom1.infra.int"
  subdirectory    = "/mojshared002$/FITS_3635/Shared/Group/SIS Case Management/"

  user     = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["password"]

  agent_arns = [aws_datasync_agent.main.arn]

  tags = local.tags
}

