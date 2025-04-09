data "template_file" "script" {
  template = file("${path.module}/scripts/recreate_external_schemas_template.tpl")

  vars = {
    postgres_uri = "uri to be replaced"
    iam_role = aws_iam_role.ycs-team.arn
    secret_arn = var.rds_redshift_secret_arn
  }
}

resource "local_file" "rendered_template" {
  content  = data.template_file.script.rendered
  filename = "${path.module}/scripts/recreate_external_schemas_${var.environment}.sql"
}