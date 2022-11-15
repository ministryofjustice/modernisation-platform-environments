output "dms_private_subnet_ids" {
  value = aws_subnet.database.*.id
}
