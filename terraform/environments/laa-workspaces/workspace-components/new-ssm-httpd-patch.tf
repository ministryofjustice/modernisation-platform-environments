##############################################
### SSM association - patch Apache httpd on the RADIUS EC2
###
### STB-5247: CybelAngel flagged Apache 2.4.66 (CVE-2026-119618 and
### others) on workspace-mfa. The instance is only built once by
### user_data and Terraform ignores AMI changes, so package updates
### are applied here with an SSM association. The association runs
### once on creation and again whenever the command changes.
### HTTP/2 is also removed from Protocols: the ALB only talks
### HTTP/1.1 to the target and mod_http2 is inactive under prefork.
##############################################

resource "aws_ssm_association" "radius_server_httpd_patch" {
  count = local.environment == "development" ? 1 : 0

  name             = "AWS-RunShellScript"
  association_name = "${local.application_name}-${local.environment}-radius-httpd-patch"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.radius_server[0].id]
  }

  parameters = {
    commands = join(" && ", [
      "yum -y --disablerepo='*' --enablerepo=amzn2-core update httpd mod_http2 mod_ssl",
      "sed -i -E 's#^Protocols .*#Protocols http/1.1#' /etc/httpd/conf/httpd.conf",
      "apachectl configtest",
      "systemctl restart httpd",
      "httpd -v",
      "rpm -q httpd mod_http2 mod_ssl",
    ])
  }

  compliance_severity = "CRITICAL"
}
