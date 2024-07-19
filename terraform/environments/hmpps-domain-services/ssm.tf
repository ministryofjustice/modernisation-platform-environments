resource "aws_ssm_document" "rds_gateway" {
  name            = "rds-gateway"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/rds-gateway.yaml")

  tags = merge(
    local.tags,
    {
      Name = "rds-gateway"
    },
  )
}

resource "aws_ssm_document" "rds_deploy" {
  name            = "rds-deploy"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/rds-deploy.yaml")

  tags = merge(
    local.tags,
    {
      Name = "rds-deploy"
    },
  )
}

resource "aws_ssm_document" "rds_collection" {
  name            = "rds_collection"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/rds-collection.yaml")

  tags = merge(
    local.tags,
    {
      Name = "rds-collection"
    },
  )
}

resource "aws_ssm_document" "rds_app" {
  name            = "rds_app"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/rds-app.yaml")

  tags = merge(
    local.tags,
    {
      Name = "rds-app"
    },
  )
}

resource "aws_ssm_document" "winrm_https" {
  name            = "winrm_https"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/winrm_https.yaml")

  tags = merge(
    local.tags,
    {
      os-type = "Windows"
    },
  )
}
