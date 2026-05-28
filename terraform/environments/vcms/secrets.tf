resource "aws_ssm_parameter" "db_user" {
  name  = "db-user"
  type  = "String"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "db-user"
    },
  )
}

resource "aws_ssm_parameter" "db_hostname" {
  name  = "db-hostname"
  type  = "String"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "db-hostname"
    },
  )
}

resource "aws_ssm_parameter" "database_name" {
  name  = "database-name"
  type  = "String"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "db-database-name"
    },
  )
}

resource "aws_ssm_parameter" "vcms_bucket_name" {
  name  = "vcms-bucket-name"
  type  = "String"
  value = module.vcms_bucket.bucket.id

  tags = merge(
    local.tags,
    {
      Name = ""
    },
  )
}
