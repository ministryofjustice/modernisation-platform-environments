module "eks" {
    source  = "./cluster"
    
    cluster_arn = module.eks.cluster_arn
}
