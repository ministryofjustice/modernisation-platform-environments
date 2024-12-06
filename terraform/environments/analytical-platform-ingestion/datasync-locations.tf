resource "aws_datasync_location_s3" "mojap_datasync_s3" {
  s3_bucket_arn = module.datasync_bucket.s3_bucket_arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
  }

  tags = local.tags
}

resource "aws_datasync_location_smb" "dom1_hq_pgo_shared_group_sis_case_management_investigations" {
  server_hostname = "dom1.infra.int"
  subdirectory    = "/data/hq/PGO/Shared/Group/SIS Case Management/Investigations/"

  user     = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["password"]

  agent_arns = [aws_datasync_agent.main.arn]

  tags = local.tags
}

resource "aws_datasync_location_smb" "dom1_hq_pgo_shared_group_sis_case_management_itas" {
  server_hostname = "dom1.infra.int"
  subdirectory    = "/data/hq/PGO/Shared/Group/SIS Case Management/ITAS/"

  user     = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.datasync_dom1.secret_string)["password"]

  agent_arns = [aws_datasync_agent.main.arn]

  tags = local.tags
}
