resource "aws_datasync_location_s3" "opg_investigations" {
  s3_bucket_arn = module.datasync_opg_investigations_bucket.s3_bucket_arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
  }

  tags = local.tags
}

resource "aws_datasync_location_smb" "opg_investigations" {
  server_hostname = "eucw4171nas002.dom1.infra.int"
  subdirectory    = "/mojshared002$/FITS_3635/Shared/Group/SIS Case Management/Investigations/Cases/Investigation Cases/"

  user     = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["password"]

  agent_arns = [aws_datasync_agent.main.arn]

  tags = local.tags
}

