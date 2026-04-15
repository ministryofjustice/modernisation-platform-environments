variable "route_table_id" {
  type = string
}

variable "destination_cidr_blocks" {
  type = list(string)
}

variable "transit_gateway_id" {
  type = string
}
