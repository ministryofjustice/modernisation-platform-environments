locals {

  azure_studio_hosting_cidr = {
    aks_studio_hosting_live_1_vnet = "10.244.0.0/20"
    aks_studio_hosting_dev_1_vnet  = "10.247.0.0/20"
    aks_studio_hosting_ops_1_vnet  = "10.247.32.0/20"
  }

  azure_studio_hosting_public = {
    devtest = "20.49.136.163/32"
    prod    = "20.49.225.111/32"
  }

  azure_studio_hosting_cidrs = {
    devtest = [
      local.azure_studio_hosting_cidr.aks_studio_hosting_dev_1_vnet,
    ]
    prod = [
      local.azure_studio_hosting_cidr.aks_studio_hosting_live_1_vnet,
    ]
  }

}
