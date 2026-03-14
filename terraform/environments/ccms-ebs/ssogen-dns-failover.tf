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
    ts     = timestamp()
  }

  provisioner "local-exec" {
    command = join(" ", [
      "aws ssm send-command",
      "--document-name", "AWS-RunShellScript",
      "--instance-ids", "${triggers.host_a}",
      "--parameters", "'commands=[\"./select_backend_and_store.sh ${triggers.host_a} ${triggers.port_a} ${triggers.host_b} ${triggers.port_b} SELECTED_BACKEND ${data.aws_region.current.id}\"]'",
      "--region", "${data.aws_region.current.id}",
      "--comment", "'tf select backend'"
    ])
  }
}

# Wait/poll logic is often added; for brevity we assume script is quick and parameter is available.
data "aws_ssm_parameter" "selected_backend" {
  depends_on = [null_resource.ssm_pick_backend]
  name       = "SELECTED_BACKEND"
}
