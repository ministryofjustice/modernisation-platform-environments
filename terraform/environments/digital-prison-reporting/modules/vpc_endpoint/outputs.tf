output "vpc_endpoint_arn" {
  value = var.setup_vpc_endpoint ? join("", aws_vpc_endpoint.this.arn) : ""
}

output "vpc_endpoint_id" {
  value = var.setup_vpc_endpoint ? join("", aws_vpc_endpoint.this.id) : ""
}