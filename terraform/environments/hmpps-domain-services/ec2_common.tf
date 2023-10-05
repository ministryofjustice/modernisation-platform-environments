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

resource "aws_ssm_association" "windowsdomainjoinassociation" {
    name = aws_ssm_document.windows_domain_join.name
    targets {
        key = "tag:run_windows_domain_join"
        values = ["true"]
    }
}
