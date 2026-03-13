# Render DNS change template
data "template_file" "dns_change" {
  count    = local.is-development || local.is-test ? 1 : 0
  template = file("${path.module}/templates/dns-change.json.tpl")

  vars = {
    record_name = aws_route53_record.ssogen_admin_primary[count.index].name
  }
}

resource "local_file" "dns_change" {
  count    = local.is-development || local.is-test ? 1 : 0
  filename = "${path.module}/dns-change.json"
  content  = data.template_file.dns_change[count.index].rendered
}

resource "null_resource" "conditional_dns_update" {
  count    = local.is-development || local.is-test ? 1 : 0
  provisioner "local-exec" {
    command = <<EOF
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::${data.aws_caller_identity.current.id}:role/MemberInfrastructureAccess --role-session-name github-actions-session)
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
./scripts/update_dns_ssogen_admin.sh \
${data.aws_instance.ssogen_primary_details[count.index].private_ip} \
${local.application_data.accounts[local.environment].tg_ssogen_admin_port} \
${data.aws_instance.ssogen_secondary_details[count.index].private_ip} \
${data.aws_route53_zone.external.zone_id} \
${local_file.dns_change[count.index].filename}
EOF
  }
  depends_on = [local_file.dns_change]
}
