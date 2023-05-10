resource "aws_efs_file_system" "foo" {
  creation_token = format("%s-openldap", local.application_name)
}
