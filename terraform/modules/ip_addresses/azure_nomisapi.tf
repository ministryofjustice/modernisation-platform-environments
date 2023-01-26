locals {

  azure_nomisapi_cidr = {
    nomisapi_t2_root_vnet      = "10.47.0.192/26"
    nomisapi_t3_root_vnet      = "10.47.0.0/26"
    nomisapi_preprod_root_vnet = "10.47.0.64/26"
    nomisapi_prod_root_vnet    = "10.47.0.128/26"
  }

  azure_nomisapi_cidrs = {
    devtest = [
      local.azure_nomisapi_cidr.nomisapi_t2_root_vnet,
      local.azure_nomisapi_cidr.nomisapi_t3_root_vnet,
    ]
    prod = [
      local.azure_nomisapi_cidr.nomisapi_preprod_root_vnet,
      local.azure_nomisapi_cidr.nomisapi_prod_root_vnet,
    ]
  }

}
