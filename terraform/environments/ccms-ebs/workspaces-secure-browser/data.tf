data "http" "azure_service_tags_index" {
  url = "https://www.microsoft.com/en-us/download/details.aspx?id=56519"
  request_headers = {
    Accept = "text/html"
  }
}

data "http" "azure_service_tags_json" {
  url = local.latest_json_url
  request_headers = {
    Accept = "application/json"
  }
}


data "aws_subnet" "private_aza" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2a"]
  }
}

data "aws_subnet" "private_azc" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2c"]
  }
}

data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}