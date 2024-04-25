resource "aws_security_group" "dms" {
  vpc_id = var.account_info.vpc_id
  name = "Modernisation-platform-DMS-security_group"
  description = "Security group for aws DMS service in Mod platformn"
}
