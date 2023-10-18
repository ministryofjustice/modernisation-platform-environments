resource "aws_ssm_document" "windows_domain_join" {
  name            = "windows-domain-join"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/windows-domain-join.yaml")

  tags = merge(
    local.tags,
    {
      Name = "windows-domain-join"
    },
  )
}