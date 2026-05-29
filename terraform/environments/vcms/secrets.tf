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
      Name = "vcms-bucket-name"
    },
  )
}

resource "aws_ssm_parameter" "auto_user" {
  name  = "auto-user"
  type  = "SecureString"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "auto-user"
    },
  )
}

resource "aws_ssm_parameter" "auto_password" {
  name  = "auto-password"
  type  = "SecureString"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "auto-password"
    },
  )
}

resource "aws_ssm_parameter" "admin_user" {
  name  = "admin-user"
  type  = "SecureString"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "admin-user"
    },
  )
}

resource "aws_ssm_parameter" "admin_password" {
  name  = "admin-password"
  type  = "SecureString"
  value = "CHANGE_ME"

  tags = merge(
    local.tags,
    {
      Name = "admin-password"
    },
  )
}