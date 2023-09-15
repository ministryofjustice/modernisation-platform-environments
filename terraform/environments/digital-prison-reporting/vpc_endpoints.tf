module "vpc_endpoints" {
  source  = "./modules/endpoints"

  vpc_id  = local.dpr_vpc

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = ["rtb-0a92da52c0aefb033", ]
      policy          = ""
    }
  }
}