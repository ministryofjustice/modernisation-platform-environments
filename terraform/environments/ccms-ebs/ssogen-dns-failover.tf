# Render DNS change template
# data "template_file" "dns_change" {
#   count    = local.is-development || local.is-test ? 1 : 0
#   template = file("${path.module}/templates/select-active-console.json.tpl")

#   vars = {
#     record_name = aws_route53_record.ssogen_admin_primary[count.index].name
#   }
# }

# resource "local_file" "dns_change" {
#   count    = local.is-development || local.is-test ? 1 : 0
#   filename = "${path.module}/select_active_console_admin.sh"
#   content  = data.template_file.dns_change[count.index].rendered
# }


resource "null_resource" "ssm_pick_backend" {
  triggers = {
    host_a = "${data.aws_instance.ssogen_primary_details[0].private_ip}"
    port_a = tostring(7001)
    host_b = "${data.aws_instance.ssogen_secondary_details[0].private_ip}"
    port_b = tostring(7001)
    param  = "/tf/ssogen/selected_backend/ip"
    ts     = timestamp()
  }

  provisioner "local-exec" {
    command = join(" ", [
      "aws ssm send-command",
      "--document-name", "AWS-RunShellScript",
      "--instance-ids", "${data.aws_instance.ssogen_primary_details[0].id}",
      "--region", "${data.aws_region.current.id}",
      "--comment", "tf select backend",
      "--parameters",
      "'commands=[\"bash\",\"-lc\",\"set -euo pipefail",
      "check_tcp() { nc -z -w2 $1 $2; }",
      "HOST_A=${self.triggers.host_a}",
      "PORT_A=${self.triggers.port_a}",
      "HOST_B=${self.triggers.host_b}",
      "PORT_B=${self.triggers.port_b}",
      "PARAM=${self.triggers.param}",
      "REGION=${data.aws_region.current.name}",
      "SELECTED=''",
      "if check_tcp $HOST_A $PORT_A; then",
      "  SELECTED=$HOST_A",
      "elif check_tcp $HOST_B $PORT_B; then",
      "  SELECTED=$HOST_B",
      "else",
      "  echo 'No backend is responsive' >&2; exit 1",
      "fi",
      "aws ssm put-parameter --name $PARAM --value $SELECTED --type String --overwrite --region $REGION",
      "echo Stored $SELECTED in $PARAM\" ]'"
    ])
  }
}

# Wait/poll logic is often added; for brevity we assume script is quick and parameter is available.
data "aws_ssm_parameter" "selected_backend" {
  depends_on = [null_resource.ssm_pick_backend]
  name       = "/tf/ssogen/selected_backend/ip"
}
