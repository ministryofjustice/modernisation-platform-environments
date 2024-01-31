data "aws_ami" "oracle_db" {
  owners      = [var.db_ami.owner]
  name_regex  = var.db_ami.name_regex
  most_recent = true
}